//
//  ChatChannel.swift
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

public typealias PubNubChatChannel = ChatChannel<VoidCustomData>

@dynamicMemberLookup
public struct ChatChannel<Custom: ChannelCustomData>: Identifiable, Codable, Hashable {
  
  public struct ChatChannelDefault: Hashable {
    public var type: String
    public var avatarURL: URL?
    
    public init() {
      self.init(type: "default")
    }
    
    public init(
      type: String?,
      avatarURL: URL? = nil
    ) {
      if let type = type {
        self.init(type: type, avatarURL: avatarURL)
      } else {
        self.init()
        self.avatarURL = avatarURL
      }
    }
    
    public init(
      type: String,
      avatarURL: URL? = nil
    ) {
      self.type = type
      self.avatarURL = avatarURL
    }
  }
  
  public let id: String

  public var name: String?
  public var details: String?
  public var updated: Date?
  public var eTag: String?

  // `Custom` data required by PubNubCHat
  public var defaultChannel: ChatChannelDefault
  // Additional `Custom` data not required
  public var customChannel: Custom

  public init(
    id: String ,
    name: String?,
    type: String,
    details: String? = nil,
    avatarURL: URL? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    custom: Custom = Custom()
  ) {
    self.id = id
    self.name = name
    self.details = details
    self.defaultChannel = ChatChannelDefault(type: type, avatarURL: avatarURL)
    self.customChannel = custom
  }
  
  // MARK: Dynamic Member Lookup
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom, T>) -> T {
    get { customChannel[keyPath: keyPath] }
    set { customChannel[keyPath: keyPath] = newValue }
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<ChatChannelDefault, T>) -> T {
    get { defaultChannel[keyPath: keyPath] }
    set { defaultChannel[keyPath: keyPath] = newValue }
  }
  
  // MARK: Codable

  public enum CodingKeys: String, CodingKey {
    case id, name, updated, eTag
    case details = "description"
    case custom
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    let defaultChannel = try container.decode(ChatChannelDefault.self, forKey: .custom)
    
    self.init(
      id: try container.decode(String.self, forKey: .id),
      name: try container.decode(String.self, forKey: .name),
      type: defaultChannel.type,
      details: try container.decodeIfPresent(String.self, forKey: .details),
      avatarURL: defaultChannel.avatarURL,
      updated: try container.decodeIfPresent(Date.self, forKey: .updated),
      eTag: try container.decodeIfPresent(String.self, forKey: .eTag),
      custom: try container.decode(Custom.self, forKey: .custom)
    )
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
  
    try container.encodeIfPresent(details, forKey: .details)
    try container.encodeIfPresent(updated, forKey: .updated)
    try container.encodeIfPresent(eTag, forKey: .eTag)

    let customJSON = defaultChannel.flatJSON.merging(customChannel.flatJSON) { _, new in new }
    
    try container.encode(customJSON.mapValues { $0.codableValue }, forKey: .custom)
  }
}

// MARK: ChatChannelDefault Extension

extension ChatChannel.ChatChannelDefault: Codable {
  public enum CodingKeys: String, CodingKey {
    case type
    case avatarURL = "profileUrl"
  }
}

extension ChatChannel.ChatChannelDefault: ChannelCustomData {
  
  public init(flatJSON: [String: JSONCodableScalar]?) {
    self.init(
      type: flatJSON?["type"]?.stringOptional,
      avatarURL: flatJSON?["profileUrl"]?.urlOptional
    )
  }

  public var flatJSON: [String: JSONCodableScalar] {
    var json: [String: JSONCodableScalar] = ["type": type]
    
    if let url = avatarURL {
      json.updateValue(url, forKey: "profileUrl")
    }
    
    return json
  }
}

// MARK: PubNubChannelMetadata Extension

extension ChatChannel: PubNubChannelMetadata {
  public var metadataId: String {
    return id
  }
  
  public var channelDescription: String? {
    get {
      return details
    }
    set(newValue) {
      details = newValue
    }
  }
  
  public var custom: [String : JSONCodableScalar]? {
    get {
      defaultChannel.flatJSON.merging(customChannel.flatJSON) { _, new in new }
    }
    set(newValue) {
      self.defaultChannel = ChatChannelDefault(flatJSON: newValue)
      self.customChannel = Custom(flatJSON: newValue)
    }
  }
  
  public init(from other: PubNubChannelMetadata) throws {
    let custom = ChatChannelDefault(flatJSON: other.custom)
    
    self.init(
      id: other.metadataId,
      name: other.name,
      type: custom.type,
      details: other.channelDescription,
      avatarURL: custom.avatarURL,
      updated: other.updated,
      eTag: other.eTag,
      custom: Custom(flatJSON: other.custom)
    )
  }
}
