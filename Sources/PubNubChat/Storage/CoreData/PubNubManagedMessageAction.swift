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

  public var pubnubActionTimetoken: Timetoken {
    return published
  }

  public var managedUser: PubNubManagedUser {
    return author
  }

  public var managedMessage: PubNubManagedMessage {
    return parent
  }

  public func convert<Custom: ChatCustomData>() throws -> ChatMessageAction<Custom> {
    return ChatMessageAction(
      actionTimetoken: published,
      parentTimetoken: pubnubParentTimetoken,
      sourceType: sourceType,
      value: value,
      pubnubUserId: pubnubUserId,
      pubnubChannelId: parent.pubnubChannelId
    )
  }

  public convenience init<Custom: ChatCustomData>(
    chat messageAction: ChatMessageAction<Custom>,
    parent message: PubNubManagedMessage? = nil,
    author user: PubNubManagedUser? = nil,
    context: NSManagedObjectContext
  ) throws {
    self.init(context: context)

    self.updateFields(from: messageAction)

    // Set, fetch, or insert the parent
    if let message = message {
      self.parent = message
    } else if let messageModel = messageAction.messageModel {
      self.parent = try PubNubManagedMessage.insertOrUpdate(message: messageModel, processMessageActions: false, into: context)
    } else if let existingMessage = try context.fetch(
      PubNubManagedMessage.messageBy(pubnubTimetoken: messageAction.parentTimetoken, channelId: messageAction.pubnubChannelId)
    ).first {
      self.parent = existingMessage
    } else {
      PubNub.log.error("Message Action failed to init due to missing message \(messageAction.messageTimetoken) on channel \(messageAction.pubnubChannelId)")
      throw ChatError.missingRequiredData
    }
    
    // Set, fetch, or insert the author
    if let user = user {
      self.author = user
    } else if let existingUser = try context.fetch(PubNubManagedUser.userBy(pubnubId: messageAction.pubnubUserId)).first {
      self.author = existingUser
    } else if let userModel = messageAction.userModel {
      self.author = try PubNubManagedUser.insertOrUpdate(user: userModel, into: context)
    }  else {
      PubNub.log.error("Message Action failed to init due to missing user \(messageAction.pubnubUserId) on channel \(messageAction.pubnubChannelId)")
      throw ChatError.missingRequiredData
    }
  }

  // Fetchable Context

  @discardableResult
  public static func insertOrUpdate<Custom: ChatCustomData>(
    messageAction: ChatMessageAction<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMessageAction {
    if let existingMessageAction = try? context.fetch(
      messageActionBy(messageAction: messageAction)
    ).first {
      existingMessageAction.updateFields(from: messageAction)

      if let messageModel = messageAction.messageModel {
        try PubNubManagedMessage.insertOrUpdate(message: messageModel, processMessageActions: false, into: context)
      }
      if let userModel = messageAction.userModel {
        try PubNubManagedUser.insertOrUpdate(user: userModel, into: context)
      }

      return existingMessageAction
    }
    
    // Create new object from context
    return try PubNubManagedMessageAction(
      chat: messageAction,
      context: context
    )
  }

  public func updateFields<Custom: ChatCustomData>(
    from action: ChatMessageAction<Custom>
  ) {
    id = action.id
    value = action.value
    sourceType = action.sourceType
    pubnubChannelId = action.pubnubChannelId
    published = action.actionTimetoken
  }

  @discardableResult
  public static func remove(
    messageActionId: String,
    from context: NSManagedObjectContext
  ) -> PubNubManagedMessageAction? {
    if let existingMessage = try? context.fetch(
      messageActionBy(messageActionId: messageActionId)
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
    request.predicate = NSPredicate(
      format: "%K == %@",
      #keyPath(PubNubManagedMessageAction.pubnubUserId),
      pubnubUserId
    )

    return request
  }
  
  public static func messageActionsBy(messageTimetoken: Timetoken, channelId: String) -> NSFetchRequest<PubNubManagedMessageAction> {
    let request = NSFetchRequest<PubNubManagedMessageAction>(entityName: entityName)
    request.predicate = NSCompoundPredicate(
      andPredicateWithSubpredicates: [
        NSPredicate(
          format: "%K == %ld",
          #keyPath(PubNubManagedMessageAction.pubnubParentTimetoken),
          messageTimetoken),
        NSPredicate(
          format: "%K == %@",
          #keyPath(PubNubManagedMessageAction.pubnubChannelId),
          channelId)
      ])

    return request
  }

  public static func messageActionsBy(messageId: String) -> NSFetchRequest<PubNubManagedMessageAction> {
    let request = NSFetchRequest<PubNubManagedMessageAction>(entityName: entityName)
    request.predicate = NSPredicate(
      format: "%K == %@",
      #keyPath(PubNubManagedMessageAction.pubnubParentId),
      messageId
    )

    return request
  }
  
  public static func messageActionBy<CustomData: ChatCustomData>(messageAction: ChatMessageAction<CustomData>) -> NSFetchRequest<PubNubManagedMessageAction> {
    return messageActionBy(messageActionId: messageAction.id)
  }

  public static func messageActionBy(messageActionId: String) -> NSFetchRequest<PubNubManagedMessageAction> {
    let request = NSFetchRequest<PubNubManagedMessageAction>(entityName: entityName)
    request.predicate = NSPredicate(
      format: "%K == %@",
      #keyPath(PubNubManagedMessageAction.id),
      messageActionId
    )
    
    return request
  }
}
