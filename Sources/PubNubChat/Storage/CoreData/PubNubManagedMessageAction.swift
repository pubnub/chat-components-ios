//
//  PubNubManagedMessageAction.swift
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

@objc(PubNubManagedMessageAction)
public final class PubNubManagedMessageAction: NSManagedObject {
  
  // Entity Attributes
  @NSManaged public var id: String
  @NSManaged public var published: Timetoken
  
  @NSManaged public var sourceType: String
  @NSManaged public var value: String
  
  @NSManaged public var pubnubChannelId: String
  
  // Derived Attributes
  
  @NSManaged public var pubnubParentTimetoken: Timetoken
  @NSManaged public var pubnubParentId: String
  
  @NSManaged public var pubnubUserId: String
  
  // Relationships
  @NSManaged public var author: PubNubManagedUser
  @NSManaged public var parent: PubNubManagedMessage
}

// MARK: Helpers


// MARK: ManagedMessageEntity Impl.

extension PubNubManagedMessageAction: ManagedMessageActionEntity {
  
  public typealias MessageEntity = PubNubManagedMessage
  public typealias UserEntity = PubNubManagedUser

  public var pubnubActionTimetoken: Timetoken {
    return published
  }

  public var managedUser: UserEntity {
    return author
  }

  public var managedMessage: MessageEntity {
    return parent
  }

  public func convert<Custom: ChatCustomData>() throws -> ChatMessageAction<Custom> {
    return ChatMessageAction(
      actionTimetoken: published,
      parentTimetoken: pubnubParentTimetoken,
      sourceType: sourceType,
      value: value,
      pubnubUserId: pubnubUserId,
      userModel: author.convert(),
      pubnubChannelId: parent.pubnubChannelId,
      messageModel: try parent.convert()
    )
  }

  // Fetchable Context

  @discardableResult
  public static func insertOrUpdate<Custom: ChatCustomData>(
    messageAction: ChatMessageAction<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMessageAction {
    if let existingMessageAction = try? context.fetch(
      messageActionsBy(messageId: messageAction.id)
    ).first {
      try existingMessageAction.update(from: messageAction)

      if let messageModel = messageAction.messageModel {
        try PubNubManagedMessage.insertOrUpdate(message: messageModel, into: context)
      }
      if let userModel = messageAction.userModel {
        try PubNubManagedUser.insertOrUpdate(user: userModel, into: context)
      }

      return existingMessageAction
    } else {
      // Create new object from context
      return try insert(messageAction: messageAction, into: context)
    }
  }

  public static func insert<Custom: ChatCustomData>(
    messageAction: ChatMessageAction<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMessageAction {

    // Insert or Update Message
    let managedMessage: PubNubManagedMessage
    if let messageModel = messageAction.messageModel {
      managedMessage = try PubNubManagedMessage.insertOrUpdate(message: messageModel, into: context)
    } else if let existingMessage = try context.fetch(PubNubManagedMessage.messageBy(pubnubTimetoken: messageAction.parentTimetoken, channelId: messageAction.pubnubChannelId)).first {
      managedMessage = existingMessage
    } else {
      PubNub.log.error("Message failed to save due to missing stored message \(messageAction.messageTimetoken) on channel \(messageAction.pubnubChannelId)")
      throw ChatError.missingRequiredData
    }

    // Insert or Update User
    let managedUser: PubNubManagedUser
    if let userModel = messageAction.userModel {
      managedUser = try PubNubManagedUser.insertOrUpdate(user: userModel, into: context)
    } else if let existingUser = try context.fetch(PubNubManagedUser.userBy(pubnubId: messageAction.pubnubUserId)).first {
      managedUser = existingUser
    } else {
      PubNub.log.error("Message failed to save due to missing stored user \(messageAction.pubnubUserId)")
      throw ChatError.missingRequiredData
    }

    return try context.insertNew { (object: PubNubManagedMessageAction) in
      try object.update(from: messageAction)
      // Ensure Relationships are also set
      object.author = managedUser
      object.parent = managedMessage
    }
  }

  public func update<Custom: ChatCustomData>(
    from action: ChatMessageAction<Custom>
  ) throws {
    // TODO
  }

  @discardableResult
  public static func remove(
    messageActionId: String,
    from context: NSManagedObjectContext
  ) -> PubNubManagedMessageAction? {
    if let existingMessage = try? context.fetch(
      messageActionsBy(messageId: messageActionId)
    ).first {
      context.delete(existingMessage)
      return existingMessage
    }

    return nil
  }
}

// MARK: ManagedMessageActionEntityFetches Impl.

extension PubNubManagedMessageAction: ManagedMessageActionEntityFetches {
  public static func messageActionsBy(pubnubUserId: String) -> NSFetchRequest<PubNubManagedMessageAction> {
    let request = NSFetchRequest<PubNubManagedMessageAction>(entityName: entityName)
    request.predicate = NSPredicate(format: "pubnubSenderId == %@", pubnubUserId)

    return request
  }
  
  public static func messageActionsBy(messageTimetoken: Timetoken, channelId: String) -> NSFetchRequest<PubNubManagedMessageAction> {
    let request = NSFetchRequest<PubNubManagedMessageAction>(entityName: entityName)
    request.predicate = NSPredicate(format: "parentTimetoken == %@ && pubnubChannelId == %@", messageTimetoken, channelId)

    return request
  }

  public static func messageActionsBy(messageId: String) -> NSFetchRequest<PubNubManagedMessageAction> {
    let request = NSFetchRequest<PubNubManagedMessageAction>(entityName: entityName)
    request.predicate = NSPredicate(format: "pubnubParentId == %@", messageId)

    return request
  }
}
