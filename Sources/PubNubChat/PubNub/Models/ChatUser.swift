//
//  ChatUser.swift
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

import PubNub
import PubNubUser

/// The default ``ChatUser`` class not containing any Custom Properties
public typealias PubNubChatUser = ChatUser<VoidCustomData>

/// The generic `User` class used whenever a Swift PubNub API requires a `User` object.
@dynamicMemberLookup
public struct ChatUser<Custom: UserCustomData>: Identifiable, Hashable, ServerSynced {
  
  /// Custom properties that can be stored alongside the server specified User fields
  public struct CustomProperties: Hashable {
    // PubNub owned Custom Property accessed via a dynamicMember property
    // User doesn't have PubNub defaults, if some are added
    // then an additional dynamicMember should be added for access
    
    /// Developer owned generic UserCustomData
    ///  Its properties can be accessed directly from the ChatUser instance
    public var custom: Custom
    
    public init(custom: Custom) {
      self.custom = custom
    }
  }

  /// Unique identifier for the User.
  public let id: String
  /// Name of the User.
  public var name: String?
  /// Functional type of the User.
  public var type: String
  /// The current state of the User
  public var status: String?
  /// The external identifier for the User
  public var externalId: String?
  /// The profile URL for the User
  public var avatarURL: URL?
  /// The email address of the User
  public var email: String?
  /// Last time the remote object was changed.
  public var updated: Date?
  /// Caching value that changes whenever the remote object changes.
  public var eTag: String?
  /// Custom object that can be stored with the User.
  public var custom: CustomProperties
  
  public init(
    id: String,
    name: String? = nil,
    type: String? = nil,
    status: String? = nil,
    externalId: String? = nil,
    avatarURL: URL? = nil,
    email: String? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    custom: Custom = Custom()
  ) {
    self.id = id
    self.name = name
    self.type = type ?? "default"
    self.status = status
    self.externalId = externalId
    self.avatarURL = avatarURL
    self.email = email
    self.updated = updated
    self.eTag = eTag
    self.custom = CustomProperties(custom: custom)
  }
  
  // MARK: Dynamic Member Lookup
  
  // MARK: Dynamic Member Lookup
  /// Returns a binding to the resulting value of a given key path.
  /// - Parameter dynamicMember: A key path to a specific resulting value.
  /// - Returns: A new binding.
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom, T>) -> T {
    get { custom.custom[keyPath: keyPath] }
    set { custom.custom[keyPath: keyPath] = newValue }
  }
}

extension ChatUser: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubUser.CodingKeys.self)
    
    let customProperties = try container
      .decodeIfPresent(CustomProperties.self, forKey: .custom)

    self.init(
      id: try container.decode(String.self, forKey: .id),
      name: try container.decodeIfPresent(String.self, forKey: .name),
      type: try container.decodeIfPresent(String.self, forKey: .type),
      status: try container.decodeIfPresent(String.self, forKey: .status),
      externalId: try container.decodeIfPresent(String.self, forKey: .externalId),
      avatarURL: try container.decodeIfPresent(URL.self, forKey: .profileUrl),
      email: try container.decodeIfPresent(String.self, forKey: .email),
      updated: try container.decodeIfPresent(Date.self, forKey: .updated),
      eTag: try container.decodeIfPresent(String.self, forKey: .eTag),
      custom: customProperties?.custom ?? Custom()
    )
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubUser.CodingKeys.self)
    
    try container.encode(id, forKey: .id)
    try container.encodeIfPresent(name, forKey: .name)
    try container.encode(type, forKey: .type)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(externalId, forKey: .externalId)
    try container.encodeIfPresent(avatarURL, forKey: .profileUrl)
    try container.encodeIfPresent(email, forKey: .email)
    try container.encodeIfPresent(updated, forKey: .updated)
    try container.encodeIfPresent(eTag, forKey: .eTag)
    try container.encode(custom, forKey: .custom)
  }
}

// MARK: CustomProperties Extension

extension ChatUser.CustomProperties: UserCustomData {
  public init() {
    self.custom = Custom()
  }

  public init(flatJSON: [String: JSONCodableScalar]) {
    self.custom = Custom(flatJSON: flatJSON)
  }
  
  public var flatJSON: [String: JSONCodableScalar] {
    return custom.flatJSON
  }
}

extension ChatUser.CustomProperties: Codable {
  public init(from decoder: Decoder) throws {
    self.custom = try Custom(from: decoder)
  }
  
  public func encode(to encoder: Encoder) throws {
    try custom.encode(to: encoder)
  }
}

// MARK: PubNubUser Extension

extension ChatUser {
  /// Create a ``ChatUser`` from the provided `PubNubUser`
  public init(pubnub: PubNubUser) {
    self.init(
      id: pubnub.id,
      name: pubnub.name,
      type: pubnub.type,
      status: pubnub.status,
      externalId: pubnub.externalId,
      avatarURL: pubnub.profileURL,
      email: pubnub.email,
      updated: pubnub.updated,
      eTag: pubnub.eTag,
      custom: Custom(flatJSON: pubnub.custom?.flatJSON)
    )
  }
  
  /// Object that can be used to apply an update to another ``ChatUser``
  public struct Patcher {
    /// The underlying PubNubUser Patcher object
    public var pubnub: PubNubUser.Patcher
    /// The unique identifier of the object that was changed
    public var id: String { pubnub.id }
    /// The cache identifier of the change
    public var eTag: String { pubnub.eTag }
    /// The timestamp of the change
    public var updated: Date { pubnub.updated }
    
    public init(pubnub: PubNubUser.Patcher) {
      self.pubnub = pubnub
    }
  }
  
  /// Apply the patch to this ``ChatUser`` instance
  /// - Parameter patcher: The patching changeset to apply
  /// - Returns: The patched ``ChatUser`` with updated fields or a copy of this instance if no change was able to be applied
  public func patch(_ patcher: Patcher) -> ChatUser<Custom> {
    guard patcher.pubnub.shouldUpdate(userId: id, eTag: eTag, lastUpdated: updated) else {
      return self
    }

    var mutableSelf = self
    
    patcher.pubnub.apply(
      name: { mutableSelf.name = $0 },
      type: { if let value = $0 { mutableSelf.type = value } },
      status: { mutableSelf.status = $0 },
      externalId: { mutableSelf.externalId = $0 },
      profileURL: { mutableSelf.avatarURL = $0 },
      email: { mutableSelf.email = $0 },
      custom: { mutableSelf.custom = CustomProperties(flatJSON: $0?.flatJSON) },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )
    
    return mutableSelf
  }
}
