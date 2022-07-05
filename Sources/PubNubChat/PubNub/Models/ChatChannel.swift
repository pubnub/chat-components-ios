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

/// The default ``ChatChannel`` class not containing any Custom Properties
public typealias PubNubChatChannel = ChatChannel<VoidCustomData>

/// The generic `Channel` class used whenever a Swift PubNub API requires a `Space` object.
@dynamicMemberLookup
public struct ChatChannel<Custom: ChannelCustomData>: Identifiable, Hashable, ServerSynced {
  
  /// Custom properties that can be stored alongside the server specified Channel fields
  public struct CustomProperties: Hashable {
    // PubNub owned Custom Property accessed via a dynamicMember property
    /// Image you can use to visually represent the channel.
    public var avatarURL: URL?

    /// Developer owned generic ChannelCustomData
    ///  Its properties can be accessed directly from the ChatChannel instance
    public var custom: Custom

    public init(
      avatarURL: URL? = nil,
      custom: Custom = Custom()
    ) {
      self.avatarURL = avatarURL
      self.custom = custom
    }
  }
  
  /// Unique identifier for the Channel.
  public let id: String
  /// Name of the Channel.
  public var name: String?
  /// Functional type of the Channel.
  public var type: String
  /// The current state of the Channel
  public var status: String?
  /// Channel details you can display alongside the name.
  public var details: String?
  /// Last time the remote object was changed.
  public var updated: Date?
  /// Caching value that changes whenever the remote object changes.
  public var eTag: String?
  /// Custom object that can be stored with the Channel.
  public var custom: CustomProperties

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
    self.updated = updated
    self.eTag = eTag
    self.custom = CustomProperties(avatarURL: avatarURL, custom: custom)
  }
  
  // MARK: Dynamic Member Lookup
  /// Returns a binding to the resulting value of a given key path.
  /// - Parameter dynamicMember: A key path to a specific resulting value.
  /// - Returns: A new binding.
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom, T>) -> T {
    get { custom.custom[keyPath: keyPath] }
    set { custom.custom[keyPath: keyPath] = newValue }
  }
  
  /// Returns a binding to the resulting value of a given key path.
  /// - Parameter dynamicMember: A key path to a specific resulting value.
  /// - Returns: A new binding.
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<CustomProperties, T>) -> T {
    get { custom[keyPath: keyPath] }
    set { custom[keyPath: keyPath] = newValue }
  }
}

extension ChatChannel: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubSpace.CodingKeys.self)

    let customProperties = try container
      .decodeIfPresent(CustomProperties.self, forKey: .custom)

    self.init(
      id: try container.decode(String.self, forKey: .id),
      name: try container.decodeIfPresent(String.self, forKey: .name),
      type: try container.decodeIfPresent(String.self, forKey: .type),
      status: try container.decodeIfPresent(String.self, forKey: .status),
      details: try container.decodeIfPresent(String.self, forKey: .spaceDescription),
      avatarURL: customProperties?.avatarURL,
      updated: try container.decodeIfPresent(Date.self, forKey: .updated),
      eTag: try container.decodeIfPresent(String.self, forKey: .eTag),
      custom: customProperties?.custom ?? Custom()
    )
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubSpace.CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(name, forKey: .name)
    try container.encode(type, forKey: .type)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(details, forKey: .spaceDescription)
    try container.encodeIfPresent(updated, forKey: .updated)
    try container.encodeIfPresent(eTag, forKey: .eTag)
    try container.encode(custom, forKey: .custom)
  }
}

// MARK: CustomProperties Extension

extension ChatChannel.CustomProperties: ChannelCustomData {
  public init() {
    self.init(avatarURL: nil, custom: .init())
  }

  public init(flatJSON: [String: JSONCodableScalar]) {
    self.init(
      avatarURL: flatJSON[CodingKeys.avatarURL.stringValue]?.urlOptional,
      custom: Custom(flatJSON: flatJSON)
    )
  }

  public var flatJSON: [String: JSONCodableScalar] {
    var json = [String: JSONCodableScalar]()
    
    if let url = avatarURL {
      json.updateValue(url, forKey: CodingKeys.avatarURL.stringValue)
    }

    return json.merging(custom.flatJSON, uniquingKeysWith: { _, new in new })
  }
}

extension ChatChannel.CustomProperties: Codable {
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

// MARK: PubNubSpace Extension

extension ChatChannel {
  /// Create a ``ChatChannel`` from the provided `PubNubSpace`
  public init(pubnub: PubNubSpace) {
    
    let channelCustom = CustomProperties(flatJSON: pubnub.custom?.flatJSON)

    // Type was previously located inside the custom, so check in custom
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
  
  /// Object that can be used to apply an update to another ``ChatChannel``
  public struct Patcher {
    /// The underlying `PubNubSpace` Patcher object
    public var pubnub: PubNubSpace.Patcher
    /// The unique identifier of the object that was changed
    public var id: String { pubnub.id }
    /// The cache identifier of the change
    public var eTag: String { pubnub.eTag }
    /// The timestamp of the change
    public var updated: Date { pubnub.updated }
    
    public init(pubnub: PubNubSpace.Patcher) {
      self.pubnub = pubnub
    }
  }
  
  /// Apply the patch to this ``ChatChannel`` instance
  /// - Parameter patcher: The patching changeset to apply
  /// - Returns: The patched ``ChatChannel`` with updated fields or a copy of this instance if no change was able to be applied
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
      custom: { mutableSelf.custom = CustomProperties(flatJSON: $0?.flatJSON) },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )
    
    return mutableSelf
  }
}
