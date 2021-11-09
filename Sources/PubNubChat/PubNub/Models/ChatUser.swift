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

public typealias PubNubChatUser = ChatUser<VoidCustomData>

@dynamicMemberLookup
public struct ChatUser<Custom: UserCustomData>: Identifiable, Codable, Hashable {
  
  public struct PubNubDefault: Hashable, Codable {
    public var occupation: String?
    
    public init() {
      self.init(occupation: nil)
    }
    
    public init(
      occupation: String?
    ) {
      self.occupation = occupation
    }
  }
  
  public var id: String
  public var name: String?
  
  public var externalId: String?
  public var avatarURL: URL?
  public var email: String?
  
  public var updated: Date?
  public var eTag: String?

  // `Custom` data required by PubNubCHat
  public var defaultPubnub: PubNubDefault
  // Additional `Custom` data not required
  public var customUser: Custom
  
  public init(
    id: String,
    name: String?,
    occupation: String? = nil,
    externalId: String? = nil,
    avatarURL: URL? = nil,
    email: String? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    customUser: Custom = Custom()
  ) {
    self.id = id
    self.name = name
    self.externalId = externalId
    self.avatarURL = avatarURL
    self.email = email
    self.updated = updated
    self.eTag = eTag
    self.defaultPubnub = .init(occupation: occupation)
    self.customUser = customUser
  }
  
  // MARK: Dynamic Member Lookup
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom, T>) -> T {
    get { customUser[keyPath: keyPath] }
    set { customUser[keyPath: keyPath] = newValue }
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<PubNubDefault, T>) -> T {
    get { defaultPubnub[keyPath: keyPath] }
    set { defaultPubnub[keyPath: keyPath] = newValue }
  }
}

// MARK: PubNubDefault Extension

extension ChatUser.PubNubDefault: UserCustomData {
  
  public init(flatJSON: [String: JSONCodableScalar]?) {
    self.init(
      occupation: flatJSON?["occupation"]?.stringOptional
    )
  }
  
  public var flatJSON: [String: JSONCodableScalar] {
    let json: [String: JSONCodableScalar] = ["occupation": occupation]
    
    return json
  }
}

// MARK: PubNubUUIDMetadata Extension

extension ChatUser: PubNubUUIDMetadata {
  public var profileURL: String? {
    get {
      avatarURL?.absoluteString
    }
    set(newValue) {
      avatarURL = try? URL(string: newValue)
    }
  }
  
  public var metadataId: String {
    return id
  }
  
  public var custom: [String : JSONCodableScalar]? {
    get {
      defaultPubnub.flatJSON.merging(customUser.flatJSON) { _, new in new }
    }
    set(newValue) {
      self.defaultPubnub = PubNubDefault(flatJSON: newValue)
      self.customUser = Custom(flatJSON: newValue)
    }
  }
  
  public init(from other: PubNubUUIDMetadata) throws {
    let custom = PubNubDefault(flatJSON: other.custom)
    
    self.init(
      id: other.metadataId,
      name: other.name,
      occupation: custom.occupation,
      externalId: other.externalId,
      avatarURL: try URL(string: other.profileURL),
      email: other.email,
      updated: other.updated,
      eTag: other.eTag,
      customUser: Custom(flatJSON: other.custom)
    )
  }
}
