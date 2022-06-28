//
//  ManagedChatEntities.swift
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

public protocol ManagedEntity: NSManagedObject {}

// MARK: - Channel

public protocol ManagedChannelEntity: ManagedEntity {
  associatedtype MemberEntity: ManagedMemberEntity
  associatedtype MessageEntity: ManagedMessageEntity
  
  // Accessors
  
  var pubnubChannelID: String { get }

  var memberEntityCount: Int { get }
  var presentMemberEntityCount: Int { get }
  
  // Relationships
  
  var managedMembers: Set<MemberEntity> { get }
  var managedMessages: Set<MessageEntity> { get }
  
  // Model
  
  func convert<Custom: ChannelCustomData>() -> ChatChannel<Custom>
  
  // Saving
  
  @discardableResult
  static func insertOrUpdate<Custom: ChannelCustomData>(
    channel: ChatChannel<Custom>,
    into context: NSManagedObjectContext
  ) throws -> Self
  
  @discardableResult
  static func remove(
    channelId: String,
    from context: NSManagedObjectContext
  ) -> Self?
}

public protocol ManagedChannelEntityFetches: NSFetchRequestResult {
  static func channelBy(channelID: String) -> NSFetchRequest<Self>
  static func channelBy(pubnubId: String) -> NSFetchRequest<Self>
}

// MARK: - User

public protocol ManagedUserEntity: ManagedEntity {
  associatedtype MemberEntity: ManagedMemberEntity
  associatedtype MessageEntity: ManagedMessageEntity

  // Accessors
  
  var pubnubUserID: String { get }
  
  var membershipIds: [String] { get }
  
  // Relationships
  
  var managedMemberships: Set<MemberEntity> { get }
  var managedMessages: Set<MessageEntity> { get }
  
  // Model
  
  func convert<Custom: UserCustomData>() -> ChatUser<Custom>

  // Saving

  @discardableResult
  static func insertOrUpdate<Custom: UserCustomData>(
    user: ChatUser<Custom>,
    into context: NSManagedObjectContext
  ) throws -> Self
  
  @discardableResult
  static func remove(
    userId: String,
    from context: NSManagedObjectContext
  ) -> Self?
}

public protocol ManagedUserEntityFetches: NSFetchRequestResult {
  static func userBy(userId: String) -> NSFetchRequest<Self>
  static func userBy(pubnubId: String) -> NSFetchRequest<Self>
}

extension ManagedUserEntityFetches {
  public static func userBy(pubnubId: String) -> NSFetchRequest<Self> {
    return userBy(userId: pubnubId)
  }
}

// MARK: - Membership

public protocol ManagedMemberEntity: ManagedEntity {
  associatedtype ChannelEntity: ManagedChannelEntity
  associatedtype UserEntity: ManagedUserEntity
   
  // Relationships

  var managedUser: UserEntity { get }
  var managedChannel: ChannelEntity { get }
  
  // Model
  
  func convert<Custom: ChatCustomData>() -> ChatMember<Custom>

  // Saving
  
  @discardableResult
  static func insertOrUpdate<Custom: ChatCustomData>(
    member: ChatMember<Custom>,
    into context: NSManagedObjectContext
  ) throws -> Self
  
  @discardableResult
  static func remove(
    channelId: String,
    userId: String,
    from context: NSManagedObjectContext
  ) -> Self?
}

public protocol ManagedMemberEntityFetches: NSFetchRequestResult {
  static func membershipsBy(userId: String) -> NSFetchRequest<Self>
  static func membersBy(channelID: String, excludingUserId: String?, onlyPresent: Bool) -> NSFetchRequest<Self>
  static func memberBy(pubnubChannelId: String, pubnubUserId: String) -> NSFetchRequest<Self>
}

// MARK: - Message

public protocol ManagedMessageEntity: ManagedEntity {
  associatedtype ChannelEntity: ManagedChannelEntity
  associatedtype UserEntity: ManagedUserEntity
  
  // Accessors
  
  var pubnubMessageID: Timetoken { get }
  
  // Relationships
  
  var managedUser: UserEntity { get }
  var managedChannel: ChannelEntity { get }
  
  // Model
  
  func convert<Custom: ChatCustomData>() throws -> ChatMessage<Custom>
  
  @discardableResult
  static func insertOrUpdate<Custom: ChatCustomData>(
    message: ChatMessage<Custom>,
    into context: NSManagedObjectContext
  ) throws -> Self
  
  @discardableResult
  static func remove(
    messageId: String,
    from context: NSManagedObjectContext
  ) -> Self?
}

public protocol ManagedMessageEntityFetches: NSFetchRequestResult {
  static func messagesBy(pubnubUserId: String) -> NSFetchRequest<Self>
  static func messagesBy(pubnubChannelId: String) -> NSFetchRequest<Self>
  static func messagesBy(messageId: String) -> NSFetchRequest<Self>
}

// MARK: - Chat

public typealias ManagedChatChannel = ManagedChannelEntity & ManagedChannelEntityFetches
public typealias ManagedChatUser = ManagedUserEntity & ManagedUserEntityFetches
public typealias ManagedChatMember = ManagedMemberEntity & ManagedMemberEntityFetches
public typealias ManagedChatMessage = ManagedMessageEntity & ManagedMessageEntityFetches

public protocol ManagedChatEntities {
  associatedtype User: ManagedChatUser
  associatedtype Channel: ManagedChatChannel
  associatedtype Member: ManagedChatMember
  associatedtype Message: ManagedChatMessage
}

// MARK: PubNub Default Impl.

public struct PubNubManagedChatEntities: ManagedChatEntities {
  public typealias User = PubNubManagedUser
  public typealias Channel = PubNubManagedChannel
  public typealias Member = PubNubManagedMember
  public typealias Message = PubNubManagedMessage
}
