//
//  Message.swift
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

public typealias PubNubChatMessage = ChatMessage<VoidCustomData>

@dynamicMemberLookup
public struct ChatMessage<Custom: ChatCustomData>: Identifiable, Hashable, Codable {

  public struct MessagePayload: Hashable, JSONCodable {
    public var id: String
    public var text: String
    public var contentType: String?
    public var content: JSONCodable?
    public var custom: Custom.Message
    public var createdAt: Date

    enum CodingKeys: String, CodingKey {
      case id
      case text
      case contentType
      case content
      case custom
      case createdAt
    }

    public init(
      id: String = UUID().uuidString,
      text: String = String(),
      contentType: String? = nil,
      content: JSONCodable? = nil,
      custom: Custom.Message = Custom.Message(),
      createdAt: Date = Date()
    ) {
      self.id = id
      self.text = text
      self.contentType = contentType
      self.content = content
      self.custom = custom
      self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      id = try container.decode(String.self, forKey: .id)
      text = try container.decode(String.self, forKey: .text)
      contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
      content = try container.decodeIfPresent(AnyJSON.self, forKey: .content)
      custom = try container.decodeIfPresent(Custom.Message.self, forKey: .custom) ?? Custom.Message()
      createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    public init(
      jsonCodable: JSONCodable
    ) throws {
      let content = try jsonCodable.codableValue.decode(MessagePayload.self)

      self.init(
        id: content.id,
        text: content.text,
        contentType: content.contentType,
        content: content.content,
        custom: content.custom,
        createdAt: content.createdAt
      )
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(id, forKey: .id)
      try container.encode(text, forKey: .text)
      try container.encodeIfPresent(contentType, forKey: .contentType)
      try container.encodeIfPresent(content?.codableValue, forKey: .content)
      try container.encodeIfPresent(custom, forKey: .custom)
      try container.encode(createdAt, forKey: .createdAt)
    }

    public static func == (
      lhs: ChatMessage<Custom>.MessagePayload,
      rhs: ChatMessage<Custom>.MessagePayload
    ) -> Bool {
      return lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        lhs.contentType == rhs.contentType &&
        lhs.content?.codableValue == rhs.codableValue &&
        lhs.custom == rhs.custom &&
        lhs.createdAt == rhs.createdAt
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      hasher.combine(text)
      hasher.combine(contentType)
      hasher.combine(content?.codableValue)
      hasher.combine(custom)
      hasher.combine(createdAt)
    }
  }

  public var timetoken: Timetoken

  public var id: String {
    return content.id
  }

  public var content: MessagePayload

  public var pubnubUserId: String
  public var userModel: ChatUser<Custom.User>?

  public var pubnubChannelId: String
  public var channelModel: ChatChannel<Custom.Channel>?
  
  public var messageActions: [ChatMessageAction<Custom>]

  public init(
    content: MessagePayload,
    timetoken: Timetoken = 0,
    pubnubUserId: String,
    user: ChatUser<Custom.User>? = nil,
    pubnubChannelId: String,
    channel: ChatChannel<Custom.Channel>? = nil,
    messageActions: [ChatMessageAction<Custom>] = []
  ) {
    self.timetoken = timetoken

    self.content = content

    self.pubnubUserId = pubnubUserId
    self.userModel = user

    self.pubnubChannelId = pubnubChannelId
    self.channelModel = channel
    
    self.messageActions = messageActions
  }

  public init(
    id: String = UUID().uuidString,
    timetoken: Timetoken = 0,
    dateCreated: Date = Date(),
    text: String,
    contentType: String? = nil,
    content: JSONCodable? = nil,
    custom: Custom.Message = Custom.Message(),
    pubnubUserId: String,
    user: ChatUser<Custom.User>? = nil,
    pubnubChannelId: String,
    channel: ChatChannel<Custom.Channel>? = nil,
    messageActions: [ChatMessageAction<Custom>] = []
  ) {
    self.init(
      content: MessagePayload(
        id: id,
        text: text,
        contentType: contentType,
        content: content,
        custom: custom,
        createdAt: dateCreated
      ),
      timetoken: timetoken,
      pubnubUserId: pubnubUserId,
      user: user,
      pubnubChannelId: pubnubChannelId,
      channel: channel,
      messageActions: messageActions
    )
  }

  // MARK: Dynamic Member Lookup

  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom.Message, T>) -> T {
    get { content.custom[keyPath: keyPath] }
    set { content.custom[keyPath: keyPath] = newValue }
  }

  public subscript<T>(dynamicMember keyPath: WritableKeyPath<MessagePayload, T>) -> T {
    get { content[keyPath: keyPath] }
    set { content[keyPath: keyPath] = newValue }
  }
}

// MARK: PubNubMessage Ext.

extension ChatMessage: PubNubMessage {
  public var payload: JSONCodable {
    get {
      return content
    }
    set(newValue) {
      guard let newContent = try? MessagePayload(jsonCodable: newValue) else {
        PubNub.log.warn("ChatMessage could not decode \(newValue) into Message.Content")
        return
      }

      content = newContent
    }
  }

  public var actions: [PubNubMessageAction] {
    get {
      return messageActions
    }
    set(newValue) {
      messageActions = newValue.compactMap({ try? .init(from: $0) })
    }
  }

  public var publisher: String? {
    get {
      return pubnubUserId
    }
    set(newValue) {
      guard let senderId = newValue else {
        preconditionFailure("PubNub did not include Message sender")
      }
      pubnubUserId = senderId
    }
  }

  public var channel: String {
    return pubnubChannelId
  }

  public var subscription: String? {
    return pubnubChannelId
  }

  public var published: Timetoken {
    get {
      return timetoken
    }
    set(newValue) {
      timetoken = newValue
    }
  }

  public var metadata: JSONCodable? {
    get {
      return nil
    }
    set(newValue) {
      // no-op
    }
  }

  public var messageType: PubNubMessageType {
    get {
      return .message
    }
    set(newValue) {
      // no-op
    }
  }

  public init(from other: PubNubMessage) throws {

    let content = try MessagePayload(jsonCodable: other.payload)

    let senderId = other.publisher ?? ""

    self.init(
      content: content,
      timetoken: other.published,
      pubnubUserId: senderId,
      user: nil,
      pubnubChannelId: other.channel,
      channel: nil,
      messageActions: other.actions.compactMap { try? .init(from: $0) }
    )
  }
}
