//
//  ChatMessageAction.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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

public typealias PubNubChatMessageAction = ChatMessageAction<VoidCustomData>

public struct ChatMessageAction<CustomData: ChatCustomData>: Identifiable, Hashable, Codable {
  
  public private(set) var id: String
  static func composeId(
    userId: String,
    parentTimetoken: Timetoken,
    actionTimetoken: Timetoken
  ) -> String {
    return "\(userId)-\(parentTimetoken)-\(actionTimetoken)"
  }

  public var actionTimetoken: Timetoken {
    willSet {
      id = ChatMessageAction<CustomData>.composeId(
        userId: pubnubUserId,
        parentTimetoken: parentTimetoken,
        actionTimetoken: newValue
      )
    }
  }
  public var parentTimetoken: Timetoken {
    willSet {
      id = ChatMessageAction<CustomData>.composeId(
        userId: pubnubUserId,
        parentTimetoken: newValue,
        actionTimetoken: actionTimetoken
      )
    }
  }
  
  public var sourceType: String
  public var value: String
  
  public var pubnubChannelId: String
  
  public var pubnubUserId: String {
    willSet {
      id = ChatMessageAction<CustomData>.composeId(
        userId: newValue,
        parentTimetoken: parentTimetoken,
        actionTimetoken: actionTimetoken
      )
    }
  }
  public var userModel: ChatUser<CustomData.User>?

  public var messageModel: ChatMessage<CustomData>?
  
  public init(
    actionTimetoken: Timetoken,
    parentTimetoken: Timetoken,
    sourceType: String,
    value: String,
    pubnubUserId: String,
    userModel: ChatUser<CustomData.User>? = nil,
    pubnubChannelId: String,
    messageModel: ChatMessage<CustomData>? = nil
  ) {
    self.id = ChatMessageAction<CustomData>.composeId(
      userId: pubnubUserId,
      parentTimetoken: parentTimetoken,
      actionTimetoken: actionTimetoken
    )
    self.actionTimetoken = actionTimetoken
    self.parentTimetoken = parentTimetoken
    
    self.sourceType = sourceType
    self.value = value
    
    self.pubnubUserId = pubnubUserId
    self.userModel = userModel
    
    self.pubnubChannelId = pubnubChannelId
  
    self.messageModel = messageModel
  }
  
  public init(
    actionTimetoken: Timetoken,
    sourceType: String,
    value: String,
    pubnubUserId: String,
    userModel: ChatUser<CustomData.User>? = nil,
    message: ChatMessage<CustomData>
  ) {
    self.init(
      actionTimetoken: actionTimetoken,
      parentTimetoken: message.timetoken,
      sourceType: sourceType,
      value: value,
      pubnubUserId: pubnubUserId,
      userModel: userModel,
      pubnubChannelId: message.pubnubChannelId,
      messageModel: message
    )
  }
}

extension ChatMessageAction: PubNubMessageAction {
  public var actionType: String {
    return sourceType
  }
  
  public var actionValue: String {
    return value
  }
  
  public var messageTimetoken: Timetoken {
    return parentTimetoken
  }
  
  public var publisher: String {
    return pubnubUserId
  }
  
  public var channel: String {
    return pubnubChannelId
  }
  
  public var subscription: String? {
    return pubnubChannelId
  }
  
  public var published: Timetoken? {
    return actionTimetoken
  }
  
  public init(from other: PubNubMessageAction) throws {
    self.init(
      actionTimetoken: other.actionTimetoken,
      parentTimetoken: other.messageTimetoken,
      sourceType: other.actionType,
      value: other.actionValue,
      pubnubUserId: other.publisher,
      userModel: nil,
      pubnubChannelId: other.channel,
      messageModel: nil
    )
  }
}

extension PubNubMessageAction {
  var pubnubId: String {
    return "\(messageTimetoken)-\(actionTimetoken)"
  }
}
