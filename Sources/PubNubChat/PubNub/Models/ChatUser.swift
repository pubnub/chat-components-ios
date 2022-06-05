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
public struct ChatUser<Custom: UserCustomData>: Identifiable, Hashable {
  
  public struct PubNubDefault: Hashable {
    public var custom: Custom
    
    public init(custom: Custom) {
      self.custom = custom
    }
  }
  
  public let id: String
  public var name: String?

  public var type: String
  public var status: String?
  
  public var externalId: String?
  public var avatarURL: URL?
  public var email: String?
  
  public var updated: Date?
  public var eTag: String?

  // `Custom` data required by PubNubCHat
  public var customDefault: PubNubDefault
  
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
    customUser: Custom = Custom()
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
    self.customDefault = PubNubDefault(custom: customUser)
  }
  
  // MARK: Dynamic Member Lookup
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom, T>) -> T {
    get { customDefault.custom[keyPath: keyPath] }
    set { customDefault.custom[keyPath: keyPath] = newValue }
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<PubNubDefault, T>) -> T {
    get { customDefault[keyPath: keyPath] }
    set { customDefault[keyPath: keyPath] = newValue }
  }
}

// TODO: This needs to be decoded from ChatChannel so custom can be converted into
// [String: JSONCodableScalar] and then init(flatJSON: custom)
extension ChatUser: Codable {
  public init(from decoder: Decoder) throws {
    self.init(id: "TODO")
  }
  
  public func encode(to encoder: Encoder) throws {
//    try custom.encode(to: encoder)
  }
}

// MARK: PubNubDefault Extension

extension ChatUser.PubNubDefault: UserCustomData {
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

// MARK: PubNubUser Extension

extension ChatUser {
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
      customUser: Custom(flatJSON: pubnub.custom?.flatJSON)
    )
  }
  
  public struct Patcher {
    public var pubnub: PubNubUser.Patcher
    
    public var id: String { pubnub.id }
    public var eTag: String { pubnub.eTag }
    public var updated: Date { pubnub.updated }
    
    public init(pubnub: PubNubUser.Patcher) {
      self.pubnub = pubnub
    }
  }
  
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
      custom: { mutableSelf.customDefault = PubNubDefault(flatJSON: $0?.flatJSON) },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )
    
    return mutableSelf
  }
}
