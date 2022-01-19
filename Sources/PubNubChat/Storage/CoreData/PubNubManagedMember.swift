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

@objc(PubNubManagedMember)
public final class PubNubManagedMember: NSManagedObject {
  // Entity Attributes
  @NSManaged public var id: String
  @NSManaged public var custom: Data
  // Presence Attributes
  @NSManaged public var isPresent: Bool
  @NSManaged public var presenceState: Data?
  
  // Derived Attributes
  @NSManaged public var channelId: String
  @NSManaged public var userId: String
  
  // Relationships
  @NSManaged public var user: PubNubManagedUser
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
    return ChatMember<Custom>(
      pubnubChannelId: channelId,
      channel: channel.convert(),
      pubnubUserId: userId,
      user: user.convert(),
      isPresent: isPresent
    )
  }
  
  @discardableResult
  public static func insertOrUpdate<Custom: ChatCustomData>(
    member: ChatMember<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMember {
    if let existingMember = try? context.fetch(
      memberBy(pubnubChannelId: member.pubnubChannelId, pubnubUserId: member.pubnubUserId)
    ).first {
      try existingMember.update(from: member)
      
      if let channelModel = member.chatChannel {
        try PubNubManagedChannel.insertOrUpdate(channel: channelModel, into: context)
      }
      if let userModel = member.chatUser {
        try PubNubManagedUser.insertOrUpdate(user: userModel, into: context)
      }
      
      return existingMember
    } else {
      // Create new object from context
      return try insert(member: member, into: context)
    }
  }

  static func insert<Custom: ChatCustomData>(
    member: ChatMember<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMember {
    
    // Insert or update Channel
    let managedChannel: PubNubManagedChannel
    if let channelModel = member.chatChannel {
      managedChannel = try PubNubManagedChannel.insertOrUpdate(channel: channelModel, into: context)
    } else if let existingChannel = try context.fetch(PubNubManagedChannel.channelBy(pubnubId: member.pubnubChannelId)).first {
      managedChannel = existingChannel
    } else {
      PubNub.log.error("Member failed to save due to missing stored channel \(member.pubnubChannelId)")
      throw ChatError.missingRequiredData
    }
    
    // Insert or update User
    let managedUser: PubNubManagedUser
    if let userModel = member.chatUser {
      managedUser = try PubNubManagedUser.insertOrUpdate(user: userModel, into: context)
    } else if let existingUser = try context.fetch(PubNubManagedUser.userBy(pubnubId: member.pubnubUserId)).first {
      managedUser = existingUser
    } else {
      PubNub.log.error("Member failed to save due to missing stored user \(member.pubnubUserId)")
      throw ChatError.missingRequiredData
    }
    
    return try context.insertNew { (managed: PubNubManagedMember) in
      try managed.update(from: member)
      // Ensure Relationships are also set
      managed.channel = managedChannel
      managed.user = managedUser
    }

  }
  
  func update<Custom>(
    from member: ChatMember<Custom>
  ) throws where Custom : ChatCustomData {
    self.id = member.id
    
    if let isPresent = member.presence?.isPresent {
      self.isPresent = isPresent
    }
    if let presenceState = member.presence?.presenceState?.jsonData {
      self.presenceState = presenceState
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
