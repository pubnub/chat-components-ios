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
import PubNubSpace

public typealias PubNubChatChannel = ChatChannel<VoidCustomData>

@dynamicMemberLookup
public struct ChatChannel<Custom: ChannelCustomData>: Identifiable, Hashable {
  
  public struct ChatChannelDefault: Hashable {

    public var avatarURL: URL?
    public var custom: Custom

    public init(
      avatarURL: URL? = nil,
      custom: Custom = Custom()
    ) {
      self.avatarURL = avatarURL
      self.custom = custom
    }
  }
  
  public let id: String
  public var name: String?
  
  public var type: String
  public var status: String?

  public var details: String?
  public var updated: Date?
  public var eTag: String?

  public var customDefault: ChatChannelDefault

  public init(
    id: String ,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    details: String? = nil,
    avatarURL: URL? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    custom: Custom = Custom()
  ) {
    self.id = id
    self.name = name
    self.type = type ?? "default"
    self.status = status
    self.details = details
    self.customDefault = ChatChannelDefault(avatarURL: avatarURL, custom: custom)
  }
  
  // MARK: Dynamic Member Lookup
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom, T>) -> T {
    get { customDefault.custom[keyPath: keyPath] }
    set { customDefault.custom[keyPath: keyPath] = newValue }
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<ChatChannelDefault, T>) -> T {
    get { customDefault[keyPath: keyPath] }
    set { customDefault[keyPath: keyPath] = newValue }
  }

  // MARK: Codable

  public enum CodingKeys: String, CodingKey {
    case id, name, updated, eTag
    case details = "description"
    case custom
  }
  
//  public init(from decoder: Decoder) throws {
//    let container = try decoder.container(keyedBy: CodingKeys.self)
//
//    let defaultChannel = try container.decode(ChatChannelDefault.self, forKey: .custom)
//
//    self.init(
//      id: try container.decode(String.self, forKey: .id),
//      name: try container.decode(String.self, forKey: .name),
//      type: defaultChannel.type,
//      details: try container.decodeIfPresent(String.self, forKey: .details),
//      avatarURL: defaultChannel.avatarURL,
//      updated: try container.decodeIfPresent(Date.self, forKey: .updated),
//      eTag: try container.decodeIfPresent(String.self, forKey: .eTag),
//      custom: try container.decode(Custom.self, forKey: .custom)
//    )
//  }
//
//  public func encode(to encoder: Encoder) throws {
//    var container = encoder.container(keyedBy: CodingKeys.self)
//
//    try container.encode(id, forKey: .id)
//    try container.encode(name, forKey: .name)
//
//    try container.encodeIfPresent(details, forKey: .details)
//    try container.encodeIfPresent(updated, forKey: .updated)
//    try container.encodeIfPresent(eTag, forKey: .eTag)
//
//    let customJSON = defaultChannel.flatJSON.merging(customChannel.flatJSON) { _, new in new }
//
//    try container.encode(customJSON.mapValues { $0.codableValue }, forKey: .custom)
//  }
}

// TODO: This needs to be decoded from ChatChannel so custom can be converted into
// [String: JSONCodableScalar] and then init(flatJSON: custom)
extension ChatChannel.ChatChannelDefault: Codable {
  public enum CodingKeys: String, CodingKey {
    case avatarURL = "profileUrl"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    self.avatarURL = try container.decodeIfPresent(URL.self, forKey: .avatarURL)
    self.custom = try Custom(from: decoder)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
    try custom.encode(to: encoder)
  }
}

extension ChatChannel: Codable {
  public init(from decoder: Decoder) throws {
    self.init(id: "TODO")
  }
  
  public func encode(to encoder: Encoder) throws {
    //    try custom.encode(to: encoder)
  }
}

// MARK: ChatChannelDefault Extension

extension ChatChannel.ChatChannelDefault: ChannelCustomData {
  public init() {
    self.init(avatarURL: nil, custom: .init())
  }

  public init(flatJSON: [String: JSONCodableScalar]) {
    self.init(
      avatarURL: flatJSON["profileUrl"]?.urlOptional,
      custom: Custom(flatJSON: flatJSON)
    )
  }

  public var flatJSON: [String: JSONCodableScalar] {
    var json = [String: JSONCodableScalar]()
    
    if let url = avatarURL {
      json.updateValue(url, forKey: "profileUrl")
    }

    return json.merging(custom.flatJSON, uniquingKeysWith: { _, new in new })
  }
}

// MARK: PubNubSpace Extension

extension ChatChannel {
  public init(pubnub: PubNubSpace) {
    
    let channelCustom = ChatChannelDefault(flatJSON: pubnub.custom?.flatJSON)

    // Type was previously located inside the custom, so we check to a certain point
    self.init(
      id: pubnub.id,
      name: pubnub.name,
      type: pubnub.type ?? pubnub.custom?.flatJSON["type"]?.stringOptional,
      status: pubnub.status,
      details: pubnub.spaceDescription,
      avatarURL: channelCustom.avatarURL,
      updated: pubnub.updated,
      eTag: pubnub.eTag,
      custom: channelCustom.custom
    )
  }
  
  public struct Patcher {
    public var pubnub: PubNubSpace.Patcher
    
    public var id: String { pubnub.id }
    public var eTag: String { pubnub.eTag }
    public var updated: Date { pubnub.updated }
    
    public init(pubnub: PubNubSpace.Patcher) {
      self.pubnub = pubnub
    }
  }
  
  public func patch(_ patcher: Patcher) -> ChatChannel<Custom> {
    guard patcher.pubnub.shouldUpdate(spaceId: id, eTag: eTag, lastUpdated: updated) else {
      return self
    }
    
    var mutableSelf = self
    
    patcher.pubnub.apply(
      name: { mutableSelf.name = $0 },
      type: { if let value = $0 { mutableSelf.type = value } },
      status: { mutableSelf.status = $0 },
      description: { mutableSelf.details = $0 },
      custom: { mutableSelf.customDefault = ChatChannelDefault(flatJSON: $0?.flatJSON) },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )
    
    return mutableSelf
  }
}
