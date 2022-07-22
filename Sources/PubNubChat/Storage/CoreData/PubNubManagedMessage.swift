//
//  PubNubManagedMessage.swift
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

@objc(PubNubManagedMessage)
public final class PubNubManagedMessage: NSManagedObject {
  
  // Entity Attributes
  @NSManaged public var id: String  
  @NSManaged public var timetoken: Timetoken

  @NSManaged public var dateCreated: Date
  
  @NSManaged public var text: String
  
  @NSManaged public var contentType: String
  @NSManaged public var content: Data

  @NSManaged public var custom: Data
  
  // Derived Attributes
  @NSManaged public var pubnubUserId: String
  @NSManaged public var pubnubChannelId: String

  // Relationships
  @NSManaged public var author: PubNubManagedUser
  @NSManaged public var channel: PubNubManagedChannel
  @NSManaged public var actions: Set<PubNubManagedMessageAction>
}

// MARK: Helpers

extension PubNubManagedMessage {
  public var sortedDate: Date {
    return timetoken == 0 ? dateCreated : timetoken.timetokenDate
  }
}

// MARK: ManagedMessageEntity Impl.

extension PubNubManagedMessage: ManagedMessageEntity {
  public typealias ChannelEntity = PubNubManagedChannel
  public typealias UserEntity = PubNubManagedUser

  public var pubnubMessageID: Timetoken {
    return timetoken
  }
    
  public var managedUser: UserEntity {
    return author
  }

  public var managedChannel: ChannelEntity {
    return channel
  }
  
  public func convert<Custom: ChatCustomData>() throws -> ChatMessage<Custom> {

    return ChatMessage(
      id: self.id,
      timetoken: self.timetoken,
      dateCreated: self.dateCreated,
      text: self.text,
      content: try Constant.jsonDecoder.decode(AnyJSON.self, from: self.content),
      custom: (try? Constant.jsonDecoder.decode(Custom.Message.self, from: custom)) ?? Custom.Message(),
      pubnubUserId: self.author.pubnubUserID,
      user: self.author.convert(),
      pubnubChannelId: self.channel.pubnubChannelID,
      channel: self.channel.convert(),
      messageActions: try actions.map { try $0.convert() }
    )
  }
  
  // Fetchable Context
  
  @discardableResult
  public static func insertOrUpdate<Custom: ChatCustomData>(
    message: ChatMessage<Custom>,
    prcoessMessageActions: Bool,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMessage {
    if let existingMessage = try? context.fetch(
      messageBy(messageId: message.id)
    ).first {
      try existingMessage.update(from: message)
      
      if let channelModel = message.channelModel {
        try PubNubManagedChannel.insertOrUpdate(channel: channelModel, into: context)
      }
      if let userModel = message.userModel {
        try PubNubManagedUser.insertOrUpdate(user: userModel, into: context)
      }
      
      // Add and Remove Message Actions
      if prcoessMessageActions {
        // [1, 2, 3, 4, 5]
        let existingActionIds = Set(existingMessage.actions.map { $0.id })
        // [3, 4, 5, 6, 7]
        let otherActionIds = Set(message.messageActions.map { $0.id })

        // Remove: [1, 2]
        let removeActionIds = existingActionIds.subtracting(otherActionIds)
        let removeActions = existingMessage.actions.filter { removeActionIds.contains($0.id) }
        existingMessage.actions.subtract(removeActions)
        for action in removeActions {
          context.delete(action)
        }
        
        // Add: [6, 7]
        let addActionIds = otherActionIds.subtracting(existingActionIds)
        let addActions = message.messageActions.filter { addActionIds.contains($0.id) }
        for action in addActions {
          do {
            existingMessage
              .actions.insert(try PubNubManagedMessageAction.insertOrUpdate(messageAction: action, into: context))
          } catch {
            PubNub.log.error("Could not insert Message Action while updating Message \(error)")
          }
        }
      }

      return existingMessage
    } else {
      // Create new object from context
      return try insert(message: message, into: context)
    }
  }
  
  public static func insert<Custom: ChatCustomData>(
    message: ChatMessage<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedMessage {
    
    let managedChannel: PubNubManagedChannel
    if let channelModel = message.channelModel {
      managedChannel = try PubNubManagedChannel.insertOrUpdate(channel: channelModel, into: context)
    } else if let existingChannel = try context.fetch(PubNubManagedChannel.channelBy(pubnubId: message.pubnubChannelId)).first {
      managedChannel = existingChannel
    } else {
      PubNub.log.error("Message failed to save due to missing stored channel \(message.pubnubChannelId)")
      throw ChatError.missingRequiredData
    }
    
    let managedUser: PubNubManagedUser
    if let userModel = message.userModel {
      managedUser = try PubNubManagedUser.insertOrUpdate(user: userModel, into: context)
    } else if let existingUser = try context.fetch(PubNubManagedUser.userBy(pubnubId: message.pubnubUserId)).first {
      managedUser = existingUser
    } else {
      PubNub.log.error("Message failed to save due to missing stored user \(message.pubnubUserId)")
      throw ChatError.missingRequiredData
    }
    
    return try context.insertNew { (object: PubNubManagedMessage) in
      try object.update(from: message)
      // Ensure Relationships are also set
      object.author = managedUser
      object.channel = managedChannel

      var actions = Set<PubNubManagedMessageAction>()
      for action in message.messageActions {
        do {
          actions.insert(try PubNubManagedMessageAction(chat: action, parent: object, context: context))
        } catch {
          PubNub.log.error("Could not insert Message Action while inserting Message \(error)")
        }
      }
      object.actions = actions
    }
  }
  
  public func update<Custom: ChatCustomData>(
    from message: ChatMessage<Custom>
  ) throws {
    id = message.id
    timetoken = message.timetoken
    dateCreated = message.createdAt
    text = message.text
    contentType = message.contentType ?? String()
    content = try message.content.jsonDataResult.get()
    custom = try message.custom.jsonDataResult.get()
  }
  
  @discardableResult
  public static func remove(
    messageId: String,
    from context: NSManagedObjectContext
  ) -> PubNubManagedMessage? {
    if let existingMessage = try? context.fetch(
      messageBy(messageId: messageId)
    ).first {
      context.delete(existingMessage)
      return existingMessage
    }
    
    return nil
  }
}

// MARK: ManagedMessageEntityFetches Impl.

extension PubNubManagedMessage: ManagedMessageEntityFetches {
  public static func messagesBy(pubnubUserId: String) -> NSFetchRequest<PubNubManagedMessage> {
    let request = NSFetchRequest<PubNubManagedMessage>(entityName: entityName)
    request.predicate = NSPredicate(
      format: "%K == %@",
      #keyPath(PubNubManagedMessage.pubnubUserId),
      pubnubUserId
    )
    
    return request
  }
  
  public static func messagesBy(pubnubChannelId: String) -> NSFetchRequest<PubNubManagedMessage> {
    let request = NSFetchRequest<PubNubManagedMessage>(entityName: entityName)
    request.predicate = NSPredicate(
      format: "%K == %@",
      #keyPath(PubNubManagedMessage.pubnubChannelId),
      pubnubChannelId
    )
    
    return request
  }
  
  public static func messageBy(messageId: String) -> NSFetchRequest<PubNubManagedMessage> {
    let request = NSFetchRequest<PubNubManagedMessage>(entityName: entityName)
    request.predicate = NSPredicate(
      format: "%K == %@",
      #keyPath(PubNubManagedMessage.id),
      messageId
    )
    
    return request
  }
  
  public static func messageBy(pubnubTimetoken: Timetoken, channelId: String) -> NSFetchRequest<PubNubManagedMessage> {
    let request = NSFetchRequest<PubNubManagedMessage>(entityName: entityName)
    request.predicate = NSCompoundPredicate(
      andPredicateWithSubpredicates: [
        NSPredicate(
          format: "%K == %ld",
          #keyPath(PubNubManagedMessage.timetoken),
          pubnubTimetoken),
        NSPredicate(
          format: "%K == %@",
          #keyPath(PubNubManagedMessage.pubnubChannelId),
          channelId)
      ])
    return request
  }
}
