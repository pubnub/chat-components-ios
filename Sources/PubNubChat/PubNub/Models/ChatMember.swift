//
//  ChatMembership.swift
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
import PubNubMembership
import PubNubSpace
import PubNubUser

public typealias PubNubChatMember = ChatMember<VoidCustomData>

public protocol ServerSynced {
  var eTag: String? { get set }
  var updated: Date? { get set }
}

extension ServerSynced {
  var isSynced: Bool {
    return eTag != nil && updated != nil
  }
}

@dynamicMemberLookup
public struct ChatMember<Custom: ChatCustomData>: Identifiable, Hashable, ServerSynced {
  
  public struct CustomProperties: Hashable {
    // PubNub owned Custom Property accessed via a dynamicMember property
    // Member doesn't have PubNub defaults, if some are added
    // then an additional dynamicMember should be added for access

    // User owned Custom Property accessed via a dynamicMember property
    public var custom: Custom.Member
    
    public init(custom: Custom.Member) {
      self.custom = custom
    }
  }
  
  public var id: String {
    return "\(pubnubChannelId):\(pubnubUserId)"
  }
  public var pubnubChannelId: String {
    return chatChannel.id
  }
  public var pubnubUserId: String {
    chatUser.id
  }
  
  public var status: String?

  public var updated: Date?
  public var eTag: String?
  
  // Not synced remotely
  public var chatChannel: ChatChannel<Custom.Channel>
  public var chatUser: ChatUser<Custom.User>
  
  public var custom: CustomProperties
  
  // Presence
  var presence: MembershipPresence?
  
  public init(
    channel: ChatChannel<Custom.Channel>,
    user: ChatUser<Custom.User>,
    status: String? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    isPresent: Bool? = nil,
    presenceState: JSONCodable? = nil,
    custom: Custom.Member = Custom.Member()
  ) {
    self.chatChannel = channel
    self.chatUser = user
    self.custom = CustomProperties(custom: custom)
    
    self.status = status
    self.updated = updated
    self.eTag = eTag
    
    self.presence = MembershipPresence(
      isPresent: isPresent,
      presenceState: presenceState
    )
  }
  
  public init(
    channelId: String,
    userId: String,
    status: String? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    isPresent: Bool? = nil,
    presenceState: JSONCodable? = nil,
    custom: Custom.Member = Custom.Member()
  ) {
    self.init(
      channel: .init(id: channelId),
      user: .init(id: userId),
      status: status,
      updated: updated,
      eTag: eTag,
      isPresent: isPresent,
      presenceState: presenceState,
      custom: custom
    )
  }
  
  // MARK: Dynamic Member Lookup
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom.Member, T>) -> T {
    get { custom.custom[keyPath: keyPath] }
    set { custom.custom[keyPath: keyPath] = newValue }
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<MembershipPresence, T>) -> T? {
    get { presence?[keyPath: keyPath] }
    set {
      if let value = newValue {
        presence?[keyPath: keyPath] = value
      }
    }
  }
}

extension ChatMember: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PubNubMembership.CodingKeys.self)

    let customProperties = try container
      .decodeIfPresent(CustomProperties.self, forKey: .custom)
    let user = try container.decode(ChatUser<Custom.User>.self, forKey: .user)
    let channel = try container.decode(ChatChannel<Custom.Channel>.self, forKey: .space)

    self.init(
      channel: channel,
      user: user,
      status: try container.decodeIfPresent(String.self, forKey: .status),
      updated: try container.decodeIfPresent(Date.self, forKey: .updated),
      eTag: try container.decodeIfPresent(String.self, forKey: .eTag),
      custom: customProperties?.custom ?? Custom.Member()
    )
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: PubNubMembership.CodingKeys.self)
    
    try container.encode(chatUser, forKey: .user)
    try container.encode(chatChannel, forKey: .space)
    try container.encodeIfPresent(status, forKey: .status)
    try container.encodeIfPresent(updated, forKey: .updated)
    try container.encodeIfPresent(eTag, forKey: .eTag)
    try container.encode(custom, forKey: .custom)
  }
}

// MARK: Custom Properties Extension

extension ChatMember.CustomProperties: MemberCustomData {
  public init() {
    self.custom = Custom.Member()
  }
  
  public init(flatJSON: [String: JSONCodableScalar]) {
    self.custom = Custom.Member(flatJSON: flatJSON)
  }
  
  public var flatJSON: [String: JSONCodableScalar] {
    return custom.flatJSON
  }
}

extension ChatMember.CustomProperties: Codable {
  public init(from decoder: Decoder) throws {
    self.custom = try Custom.Member(from: decoder)
  }
  
  public func encode(to encoder: Encoder) throws {
    try custom.encode(to: encoder)
  }
}


// MARK: PubNubMembership Extension

extension ChatMember {
  public init(pubnub: PubNubMembership) {
    self.init(
      channel: ChatChannel<Custom.Channel>(pubnub: pubnub.space),
      user: ChatUser<Custom.User>(pubnub: pubnub.user),
      status: pubnub.status,
      updated: pubnub.updated,
      eTag: pubnub.eTag,
      custom: Custom.Member(flatJSON: pubnub.custom?.flatJSON)
    )
  }
}

// MARK: - Presence

public struct MembershipPresenceChange: Codable, Hashable {
  public let channelId: String
  public let userId: String
  public let isPresent: Bool?
  public let presenceState: Data?

  public init?(
    channelId: String,
    userId: String,
    isPresent: Bool?,
    presenceState: Data?
  ) {
    guard isPresent != nil || presenceState != nil else { return nil }
    
    self.channelId = channelId
    self.userId = userId
    self.isPresent = isPresent
    self.presenceState = presenceState
  }

  public init?(
    channelId: String,
    userId: String,
    presenceChange: MembershipPresence?
  ) {
    self.init(
      channelId: channelId,
      userId: userId,
      isPresent: presenceChange?.isPresent,
      presenceState: presenceChange?.presenceState?.jsonData
    )
  }
}

public struct MembershipPresence: Codable, Hashable {

  public var isPresent: Bool?
  public var presenceState: AnyJSON?

  public init(
    isPresent: Bool? = nil,
    presenceState: JSONCodable? = nil
  ) {
    self.isPresent = isPresent
    self.presenceState = presenceState?.codableValue
  }

  public var isEmpty: Bool {
    return isPresent == nil && presenceState == nil
  }
}

extension ChatMember {
  // Presence Helper
  
  static func presenceMemberships(
    channelId: String, presence: PubNubPresence
  ) -> [ChatMember] {
    var memberships = [ChatMember]()
    
    // Create Presence Memberships for all Occupants
    for memberId in presence.occupants {
      memberships.append(ChatMember(
        channelId: channelId,
        userId: memberId,
        isPresent: true,
        presenceState: presence.occupantsState[memberId]
      ))
    }
    
    // Determine if there are any UUIDs in `occupantsState` not in `occupants`
    for (memberId, state) in presence.occupantsState where !presence.occupants.contains(memberId) {
      memberships.append(ChatMember(
        channelId: channelId,
        userId: memberId,
        isPresent: true,
        presenceState: state
      ))
    }
    
    return memberships
  }
  
  static func presenceMemberships(
    channelId: String, changeActions actions: [PubNubPresenceChangeAction]
  ) -> [ChatMember] {
    var memberships = [ChatMember]()
    
    // TOOD: Should this create ChatMember.Presence objects instead of full members?
    for action in actions {
      switch action {
      case .join(uuids: let uuids):
        let joins = uuids.map {
          ChatMember(channelId: channelId, userId: $0, isPresent: true)
        }
        memberships.append(contentsOf: joins)
      case .leave(uuids: let uuids), .timeout(uuids: let uuids):
        let leaves = uuids.map {
          ChatMember(channelId: channelId, userId: $0, isPresent: false)
        }
        memberships.append(contentsOf: leaves)
      case .stateChange(uuid: let uuid, state: let state):
        memberships.append(
          ChatMember(
            channelId: channelId,
            userId: uuid,
            isPresent: true,
            presenceState: state
          )
        )
      }
    }
    
    return memberships
  }
}
