//
//  UserDTO.swift
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

/// The CoreData managed `User` class used whenever a ChatUser needs to be stored locally
@objc(PubNubManagedUser)
public final class PubNubManagedUser: NSManagedObject {
  // Entity Attributes
  /// Unique identifier for the User.
  @NSManaged public var id: String
  /// Name of the User.
  @NSManaged public var name: String?
  /// Functional type of the User.
  @NSManaged public var type: String
  /// The current state of the User
  @NSManaged public var status: String?
  /// The external identifier for the User
  @NSManaged public var externalId: String?
  /// The profile URL for the User
  @NSManaged public var avatarURL: URL?
  /// The email address of the User
  @NSManaged public var email: String?
  /// Data blob that represents the Custom Properties that can be stored with the Channel.
  @NSManaged public var custom: Data
  /// Last time the remote object was changed.
  @NSManaged public var lastUpdated: Date?
  /// Caching value that changes whenever the remote object changes.
  @NSManaged public var eTag: String?
    
  // Derived Attributes

  // Relationships
  /// Channels that are currently associated with this User
  @NSManaged public var memberships: Set<PubNubManagedMember>
  /// Messages that are currently associated with this User across all Channels
  @NSManaged public var messages: Set<PubNubManagedMessage>
  /// Message Actions that are currently associated with this User across all Channels
  @NSManaged public var actions: Set<PubNubManagedMessageAction>
}

extension PubNubManagedUser: ManagedUserEntity {
  public var pubnubUserID: String {
    return id
  }
  
  public var membershipIds: [String] {
    return memberships.map({ $0.channelId })
  }
  
  public var managedMemberships: Set<PubNubManagedMember> {
    return memberships
  }
  
  public var managedMessages: Set<PubNubManagedMessage> {
    return messages
  }
  
  public func convert<Custom>() -> ChatUser<Custom> where Custom : UserCustomData {
    return ChatUser(
      id: id,
      name: name,
      type: type,
      status: status,
      externalId: externalId,
      avatarURL: avatarURL,
      email: email,
      updated: lastUpdated,
      eTag: eTag,
      custom: (try? Constant.jsonDecoder.decode(Custom.self, from: custom)) ?? Custom()
    )
  }
  
  @discardableResult
  public static func insertOrUpdate<Custom: UserCustomData>(
    user: ChatUser<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedUser {
    if let existingUser = try? context.fetch(
      userBy(userId: user.id)
    ).first {
      try existingUser.update(from: user)
      
      return existingUser
    } else {
      // Create new object from context
      return try insert(user: user, into: context)
    }
  }
  
  static func insert<Custom: UserCustomData>(
    user: ChatUser<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedUser {
    return try context.insertNew { (object: PubNubManagedUser) in
      try object.update(from: user)
    }
  }

  public static func patch<Custom: UserCustomData>(
    usingPatch patcher: ChatUser<Custom>.Patcher,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedUser {
    if let existingUser = try context.fetch(
      userBy(userId: patcher.id)
    ).first {
      let chatUser = existingUser.convert().patch(patcher)
      try existingUser.update(from: chatUser)
      
      return existingUser
    } else {
      throw ChatError.missingRequiredData
    }
  }
  
  func update<Custom>(
    from user: ChatUser<Custom>
  ) throws where Custom : UserCustomData {
    self.id = user.id
    self.name = user.name
    self.type = user.type
    self.status = user.status
    self.externalId = user.externalId
    self.avatarURL = user.avatarURL
    self.email = user.email
    self.custom = try user.custom.custom.jsonDataResult.get()
    self.lastUpdated = user.updated
    self.eTag = user.eTag
  }

  @discardableResult
  public static func remove(
    userId: String,
    from context: NSManagedObjectContext
  ) -> PubNubManagedUser? {
    if let existingUser = try? context.fetch(
      userBy(userId: userId)
    ).first {
      context.delete(existingUser)
      return existingUser
    }
    
    return nil
  }
}

extension PubNubManagedUser: ManagedUserEntityFetches {
  public static func userBy(userId: String) -> NSFetchRequest<PubNubManagedUser> {
    let request = NSFetchRequest<PubNubManagedUser>(entityName: entityName)
    request.predicate = NSPredicate(format: "id == %@", userId)
    
    return request
  }
}
