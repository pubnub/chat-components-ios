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

public typealias PubNubChatMember = ChatMember<VoidCustomData>

@dynamicMemberLookup
public struct ChatMember<CustomData: ChatCustomData>: Identifiable, Hashable {
  
  public struct PubNubDefault: Hashable {
    public var custom: CustomData.Member
    
    public init(custom: CustomData.Member) {
      self.custom = custom
    }
  }
  
  public var id: String {
    return "\(pubnubChannelId):\(pubnubUserId)"
  }
  
  public var pubnubChannelId: String
  public var pubnubUserId: String
  
  public var status: String?

  public var updated: Date?
  public var eTag: String?
  
  // Not synced remotely
  public var chatChannel: ChatChannel<CustomData.Channel>?
  public var chatUser: ChatUser<CustomData.User>?
  
  public var defaultPubnub: PubNubDefault
  
  // Presence
  var presence: MembershipPresence?
  
  public init(
    pubnubChannelId: String,
    channel: ChatChannel<CustomData.Channel>? = nil,
    pubnubUserId: String,
    user: ChatUser<CustomData.User>? = nil,
    status: String? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    isPresent: Bool? = nil,
    presenceState: JSONCodable? = nil,
    custom: CustomData.Member = CustomData.Member()
  ) {
    self.pubnubChannelId = pubnubChannelId
    self.chatChannel = channel
    self.pubnubUserId = pubnubUserId
    self.chatUser = user
    self.defaultPubnub = PubNubDefault(custom: custom)
    
    self.status = status
    self.updated = updated
    self.eTag = eTag
    
    self.presence = MembershipPresence(
      isPresent: isPresent,
      presenceState: presenceState
    )
  }
  
  public init(
    channel: ChatChannel<CustomData.Channel>,
    member: ChatUser<CustomData.User>,
    status: String? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    isPresent: Bool? = nil,
    presenceState: JSONCodable? = nil,
    custom: CustomData.Member = CustomData.Member()
  ) {
    self.init(
      pubnubChannelId: channel.id,
      channel: channel,
      pubnubUserId: member.id,
      user: member,
      status: status,
      updated: updated,
      eTag: eTag,
      isPresent: isPresent,
      presenceState: presenceState,
      custom: custom
    )
  }
  
  // MARK: Dynamic Member Lookup
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<CustomData.Member, T>) -> T {
    get { defaultPubnub.custom[keyPath: keyPath] }
    set { defaultPubnub.custom[keyPath: keyPath] = newValue }
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<PubNubDefault, T>) -> T {
    get { defaultPubnub[keyPath: keyPath] }
    set { defaultPubnub[keyPath: keyPath] = newValue }
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<MembershipPresence, T>) -> T? {
    get { presence?[keyPath: keyPath] }
    set {
      if let value = newValue {
        presence?[keyPath: keyPath] = value
      }
    }
  }
  
  // Presence Helper
  
  static func presenceMemberships(
    channelId: String, presence: PubNubPresence
  ) -> [ChatMember] {
    var memberships = [ChatMember]()
    
    // Create Presence Memberships for all Occupants
    for memberId in presence.occupants {
      memberships.append(ChatMember(
        pubnubChannelId: channelId,
        pubnubUserId: memberId,
        isPresent: true,
        presenceState: presence.occupantsState[memberId]
      ))
    }

    // Determine if there are any UUIDs in `occupantsState` not in `occupants`
    for (memberId, state) in presence.occupantsState where !presence.occupants.contains(memberId) {
      memberships.append(ChatMember(
        pubnubChannelId: channelId,
        pubnubUserId: memberId,
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
    
    // TOOD: Should this create Presence sub objects instead of full members
    for action in actions {
      switch action {
      case .join(uuids: let uuids):
        let joins = uuids.map {
          ChatMember(pubnubChannelId: channelId, pubnubUserId: $0, isPresent: true)
        }
        memberships.append(contentsOf: joins)
      case .leave(uuids: let uuids), .timeout(uuids: let uuids):
        let leaves = uuids.map {
          ChatMember(pubnubChannelId: channelId, pubnubUserId: $0, isPresent: false)
        }
        memberships.append(contentsOf: leaves)
      case .stateChange(uuid: let uuid, state: let state):
        memberships.append(
          ChatMember(
            pubnubChannelId: channelId,
            pubnubUserId: uuid,
            presenceState: state
          )
        )
      }
    }

    return memberships
  }
  
  // MARK: - MembershipPresenceChange
  
  var presenceChnage: MembershipPresenceChange? {
    return MembershipPresenceChange(
      channelId: pubnubChannelId,
      userId: pubnubUserId,
      presenceChange: presence
    )
  }
}

// TODO: This needs to be decoded from ChatChannel so custom can be converted into
// [String: JSONCodableScalar] and then init(flatJSON: custom)
extension ChatMember: Codable {
  public init(from decoder: Decoder) throws {
    self.init(pubnubChannelId: "TODO", pubnubUserId: "TODO")
  }
  
  public func encode(to encoder: Encoder) throws {
    //    try custom.encode(to: encoder)
  }
}

// MARK: PubNubDefault Extension

extension ChatMember.PubNubDefault: MemberCustomData {
  public init() {
    self.custom = CustomData.Member()
  }
  
  public init(flatJSON: [String: JSONCodableScalar]) {
    self.custom = CustomData.Member(flatJSON: flatJSON)
  }
  
  public var flatJSON: [String: JSONCodableScalar] {
    return custom.flatJSON
  }
}

// MARK: PubNubMembership Extension

extension ChatMember {
  public init(pubnub: PubNubMembership) {
    self.init(
      channel: ChatChannel<CustomData.Channel>(pubnub: pubnub.space),
      member: ChatUser<CustomData.User>(pubnub: pubnub.user),
      status: pubnub.status,
      updated: pubnub.updated,
      eTag: pubnub.eTag,
      custom: CustomData.Member(flatJSON: pubnub.custom?.flatJSON)
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
    presenceChange: MembershipPresence
  ) {
    guard !presenceChange.isEmpty else { return nil }
    
    self.init(
      channelId: channelId, userId: userId,
      isPresent: presenceChange.isPresent,
      presenceState: presenceChange.presenceState?.jsonData
    )
  }
  
  public init?(
    channelId: String,
    userId: String,
    presenceChange: MembershipPresence?
  ) {
    guard let presenceChange = presenceChange else { return nil }
    
    self.init(channelId: channelId, userId: userId, presenceChange: presenceChange)
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
