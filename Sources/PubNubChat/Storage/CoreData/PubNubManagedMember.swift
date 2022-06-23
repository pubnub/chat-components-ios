//
//  MembershipDTO.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2021 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import CoreData

import PubNub

/// The CoreData managed `Member` class used whenever a ChatMember needs to be stored locally
@objc(PubNubManagedMember)
public final class PubNubManagedMember: NSManagedObject {
  // Entity Attributes
  /// Unique identifier for the Member
  @NSManaged public var id: String
  /// Data blob that represents the Custom Properties that can be stored with the Member.
  @NSManaged public var custom: Data
  /// The current state of the Member relationship
  @NSManaged public var status: String?
  /// Last time the remote object was changed.
  @NSManaged public var lastUpdated: Date?
  /// Caching value that changes whenever the remote object changes.
  @NSManaged public var eTag: String?

  // Presence Attributes
  /// Whether the User is "Active" on a the Chanel
  @NSManaged public var isPresent: Bool
  /// State information associated with the User for the Channel
  @NSManaged public var presenceState: Data?
  
  // Derived Attributes
  /// Unique identifier for the Channel.
  @NSManaged public var channelId: String
  /// Unique identifier for the User.
  @NSManaged public var userId: String

  // Relationships
  /// User that is associated with the Channel
  @NSManaged public var user: PubNubManagedUser
  /// Channel that is associated with the User
  @NSManaged public var channel: PubNubManagedChannel
}

// MARK: ManagedMemberEntity Impl.

extension PubNubManagedMember: ManagedMemberEntity {
  public typealias ChannelEntity = PubNubManagedChannel
  public typealias UserEntity = PubNubManagedUser
  
  public var managedUser: UserEntity {
    return user
  }
  public var managedChannel: ChannelEntity {
    return channel
  }
  
  public func convert<Custom>() -> ChatMember<Custom> where Custom : ChatCustomData {
    var state: AnyJSON? = nil
    if let presenceState = presenceState {
      state = try? Constant.jsonDecoder.decode(AnyJSON.self, from: presenceState)
    }

    return ChatMember<Custom>(
      channel: channel.convert(),
      user: user.convert(),
      status: status,
      updated: lastUpdated,
      eTag: eTag,
      presence: .init(isPresent: isPresent, presenceState: state),
      custom: (try? Constant.jsonDecoder.decode(Custom.Member.self, from: custom)) ?? Custom.Member()
    )
  }
  
  @discardableResult
  public static func insertOrUpdate<Custom: ChatCustomData>(
    member: ChatMember<Custom>,
    forceWrite: Bool = false,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMember {
    if let existingMember = try? context.fetch(
      memberBy(pubnubChannelId: member.chatChannel.id, pubnubUserId: member.chatUser.id)
    ).first {
      try existingMember.update(from: member)
      
      // Write the value if it has server-set properties or if force write was specified
      if member.chatChannel.isSynced || forceWrite {
        try PubNubManagedChannel.insertOrUpdate(channel: member.chatChannel, into: context)
      }
      if member.chatUser.isSynced || forceWrite {
        try PubNubManagedUser.insertOrUpdate(user: member.chatUser, into: context)
      }
      
      return existingMember
    } else {
      // Create new object from context
      return try insert(member: member, forceWrite: forceWrite, into: context)
    }
  }

  static func insert<Custom: ChatCustomData>(
    member: ChatMember<Custom>,
    forceWrite: Bool,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMember {
    
    // Insert or update Channel
    let managedChannel: PubNubManagedChannel
    if member.chatChannel.isSynced || forceWrite {
      managedChannel = try PubNubManagedChannel.insertOrUpdate(channel: member.chatChannel, into: context)
    } else if let existingChannel = try context.fetch(PubNubManagedChannel.channelBy(pubnubId: member.chatChannel.id)).first {
      managedChannel = existingChannel
    } else {
      PubNub.log.error("Member failed to save due to missing stored channel \(member.chatChannel.id)")
      throw ChatError.missingRequiredData
    }
    
    // Insert or update User
    let managedUser: PubNubManagedUser
    if member.chatUser.isSynced || forceWrite {
      managedUser = try PubNubManagedUser.insertOrUpdate(user:  member.chatUser, into: context)
    } else if let existingUser = try context.fetch(PubNubManagedUser.userBy(pubnubId: member.chatUser.id)).first {
      managedUser = existingUser
    } else {
      PubNub.log.error("Member failed to save due to missing stored user \(member.chatUser.id)")
      throw ChatError.missingRequiredData
    }
    
    return try context.insertNew { (managed: PubNubManagedMember) in
      try managed.update(from: member)
      // Ensure Relationships are also set
      managed.channel = managedChannel
      managed.user = managedUser
    }
  }

  @discardableResult
  public static func patch<Custom: ChatCustomData>(
    usingPatch patcher: ChatMember<Custom>.Patcher,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMember {
    if let existingMember = try? context.fetch(
      memberBy(pubnubChannelId: patcher.channelId, pubnubUserId: patcher.userId)
    ).first {
      let chatMember = existingMember.convert().patch(patcher)
      try existingMember.update(from: chatMember)
      
      return existingMember
    } else {
      throw ChatError.missingRequiredData
    }
  }
  
  func update<Custom>(
    from member: ChatMember<Custom>
  ) throws where Custom : ChatCustomData {
    self.id = member.id
    self.status = member.status
    self.eTag = member.eTag
    self.lastUpdated = member.updated
    self.custom = try member.custom.custom.jsonDataResult.get()
    
    if let presence = member.presence {
      self.isPresent = isPresent
      switch presence.presenceState {
      case .noChange:
        break
      case .none:
        self.presenceState = nil
      case let .some(state):
        self.presenceState = try state.jsonDataResult.get()
      }
    }
  }
  
  @discardableResult
  public static func remove(
    channelId: String,
    userId: String,
    from context: NSManagedObjectContext
  ) -> PubNubManagedMember? {
    if let existingMember = try? context.fetch(
      memberBy(pubnubChannelId: channelId, pubnubUserId: userId)
    ).first {
      context.delete(existingMember)
      return existingMember
    }
    
    return nil
  }
}

// MARK: Queries

extension PubNubManagedMember: ManagedMemberEntityFetches {
  
  // Object Fetch
  
  public static func memberBy(
    pubnubChannelId: String, pubnubUserId: String
  ) -> NSFetchRequest<PubNubManagedMember> {
    let request = NSFetchRequest<PubNubManagedMember>(entityName: entityName)
    
    request.predicate = NSCompoundPredicate(
      type: .and,
      subpredicates: [
        NSPredicate(format: "channelId == %@", pubnubChannelId),
        NSPredicate(format: "userId == %@", pubnubUserId)
      ]
    )
    
    return request
  }
  
  // User Relationship
  
  public static func membershipsBy(userId: String) -> NSFetchRequest<PubNubManagedMember> {
    let request = NSFetchRequest<PubNubManagedMember>(entityName: entityName)
    request.predicate = NSPredicate(format: "userId == %@", userId)
    
    return request
  }

  // Channel Relationship
  
  public static func membersBy(
    channelID: String,
    excludingUserId: String?,
    onlyPresent: Bool
  ) -> NSFetchRequest<PubNubManagedMember> {
    let request = NSFetchRequest<PubNubManagedMember>(entityName: entityName)

    switch (excludingUserId, onlyPresent) {
    case let (.some(entityId), true):
      request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        NSPredicate(format: "userId != %@", entityId),
        NSPredicate(format: "isPresent == YES"),
        NSPredicate(format: "channelId == %@", channelID)
      ])
    case let (.some(entityId), false):
      request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        NSPredicate(format: "userId != %@", entityId),
        NSPredicate(format: "channelId == %@", channelID)
      ])
    case (.none, true):
      request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        NSPredicate(format: "isPresent == YES"),
        NSPredicate(format: "channelId == %@", channelID)
      ])
    case (.none, false):
      request.predicate = NSPredicate(format: "channelId == %@", channelID)
    }

    return request
  }
}

// MARK: - TransientPropertyHolder

extension PubNubManagedMember: TransientPropertyHolder {
  
  func clearTransientProperties() {
    isPresent = false
    presenceState = nil
  }
}
