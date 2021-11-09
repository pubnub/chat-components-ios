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
public struct ChatMessage<CustomData: ChatCustomData>: Identifiable, Codable {
  
  public struct Content: JSONCodable {
    public var id: String
    
    public var dateCreated: Date
    
    public var contentType: String
    public var contentPayload: MessageContent
    
    public var custom: CustomData.Message
    
    public init(
      id: String = UUID().uuidString,
      dateCreated: Date = Date(),
      content: MessageContent,
      custom: CustomData.Message
    ) {
      self.id = id
      self.dateCreated = dateCreated
      self.contentType = content.contentType.rawValue
      self.contentPayload = content
      self.custom = custom
    }
    
    public init(
      jsonCodable: JSONCodable
    ) throws {
      let content = try jsonCodable.codableValue.decode(Content.self)

      self.init(
        id: content.id,
        dateCreated: content.dateCreated,
        content: content.contentPayload,
        custom: content.custom
      )
    }
  }

  public var timetoken: Timetoken
  
  public var id: String {
    return content.id
  }

  public var dateSent: Date?
  public var dateReceived: Date?
  
  public var content: Content
  
  public var pubnubUserId: String
  public var userModel: ChatUser<CustomData.User>?
  
  public var pubnubChannelId: String
  public var channelModel: ChatChannel<CustomData.Channel>?
  
  public init(
    content: Content,
    timetoken: Timetoken = 0,
    //    sentStatus: String = "pending",
    dateSent: Date? = nil,
    dateReceived: Date? = nil,
    pubnubUserId: String,
    user: ChatUser<CustomData.User>? = nil,
    pubnubChannelId: String,
    channel: ChatChannel<CustomData.Channel>? = nil
  ) {
    self.timetoken = timetoken
    //    self.sentStatus = sentStatus
    self.dateSent = dateSent
    self.dateReceived = dateReceived
    
    self.content = content
    
    self.pubnubUserId = pubnubUserId
    self.userModel = user
    
    self.pubnubChannelId = pubnubChannelId
    self.channelModel = channel
  }
  
  public init(
    id: String = UUID().uuidString,
    timetoken: Timetoken = 0,
//    sentStatus: String = "pending",
    dateCreated: Date = Date(),
    dateSent: Date? = nil,
    dateReceived: Date? = nil,
    content: MessageContent,
    custom: CustomData.Message = CustomData.Message(),
    pubnubUserId: String,
    user: ChatUser<CustomData.User>? = nil,
    pubnubChannelId: String,
    channel: ChatChannel<CustomData.Channel>? = nil
  ) {
    self.init(
      content: Content(
        id: id,
        dateCreated: dateCreated,
        content: content,
        custom: custom
      ),
      timetoken: timetoken,
      dateSent: dateSent,
      dateReceived: dateReceived,
      pubnubUserId: pubnubUserId,
      user: user,
      pubnubChannelId: pubnubChannelId,
      channel: channel
    )
  }
  
  // MARK: Dynamic Member Lookup
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<CustomData.Message, T>) -> T {
    get { content.custom[keyPath: keyPath] }
    set { content.custom[keyPath: keyPath] = newValue }
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Content, T>) -> T {
    get { content[keyPath: keyPath] }
    set { content[keyPath: keyPath] = newValue }
  }
}

// MARK: Content Types

public enum MessageContentType: String, Codable {
  case text
  case link
  case imageRemote = "image-remote"
  case custom
  
  public init(rawValue: String) {
    switch rawValue {
    case MessageContentType.text.rawValue:
      self = .text
    case MessageContentType.link.rawValue:
      self = .link
    case MessageContentType.imageRemote.rawValue:
      self = .imageRemote
    default:
      self = .custom
    }
  }
}

public enum MessageContent {
  case text(String)
  case link(URL)
  case imageRemote(URL)
  case custom(AnyJSON)
  
  public var textType: String? {
    switch self {
    case .text(let content):
      return content
    default:
      return nil
    }
  }
  
  public var linkType: URL? {
    switch self {
    case .link(let content):
      return content
    default:
      return nil
    }
  }
  
  public var contentType: MessageContentType {
    switch self {
    case .text:
      return MessageContentType.text
    case .link:
      return MessageContentType.link
    case .imageRemote:
      return MessageContentType.imageRemote
    case .custom:
      return MessageContentType.custom
    }
  }
  
  public var jsonContent: AnyJSON {
    switch self {
    case .text(let content):
      return [contentType.rawValue: content]
    case .link(let content):
      return [contentType.rawValue: content]
    case .imageRemote(let content):
      return [contentType.rawValue: content]
    case .custom(let content):
      return content
    }
  }
}

extension MessageContent: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    let json = try container.decode(AnyJSON.self)

    if let content = json["text"]?.stringOptional {
      self = .text(content)
    } else if let content = json["link"]?.stringOptional, let contentURL = URL(string: content) {
      self = .link(contentURL)
    } else if let content = json["imageRemote"]?.stringOptional, let contentURL = URL(string: content) {
      self = .imageRemote(contentURL)
    } else {
      self = .custom(json)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    
    try container.encode(jsonContent)
  }
}

// MARK: PubNubMessage Ext.

extension ChatMessage: PubNubMessage {
  public var payload: JSONCodable {
    get {
      return content
    }
    set(newValue) {
      guard let newContent = try? Content(jsonCodable: newValue) else {
        PubNub.log.warn("ChatMessage could not decode \(newValue) into Message.Content")
        return
      }
      
      content = newContent
    }
  }
  
  public var actions: [PubNubMessageAction] {
    get {
      return []
    }
    set(newValue) {
      // no-op
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
    
    let content = try Content(jsonCodable: other.payload)
    
    let senderId = other.publisher ?? ""
    
    self.init(
      content: content,
      timetoken: other.published,
      dateSent: other.published.timetokenDate,
      dateReceived: nil,
      pubnubUserId: senderId,
      user: nil,
      pubnubChannelId: other.channel,
      channel: nil
    )
  }
}
