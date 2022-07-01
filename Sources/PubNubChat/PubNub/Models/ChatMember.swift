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

/// The default ``ChatMember`` class not containing any Custom Properties
public typealias PubNubChatMember = ChatMember<VoidCustomData>

/// The generic `Member` class used whenever a Swift PubNub API requires a `Membership` object.
@dynamicMemberLookup
public struct ChatMember<Custom: ChatCustomData>: Identifiable, Hashable, ServerSynced {
  
  /// Custom properties that can be stored alongside the server specified Member fields
  public struct CustomProperties: Hashable {
    // PubNub owned Custom Property accessed via a dynamicMember property
    // Member doesn't have PubNub defaults, if some are added
    // then an additional dynamicMember should be added for access

    /// Developer owned generic MemberCustomData
    ///  Its properties can be accessed directly from the ChatMember instance
    public var custom: Custom.Member
    
    public init(custom: Custom.Member) {
      self.custom = custom
    }
  }

  /// Unique identifier for the Member.
  ///  Computed from the `chatChannel.id` and `chatUser.id`
  public var id: String {
    return "\(chatChannel.id):\(chatUser.id)"
  }
  /// The associated `ChatChannel` for this Member
  /// - Important:Only the identifier is used when interacting with PubNub Membership APIs.  To perform operations on this object you will need to call the corresponding PubNub Channel API.
  public var chatChannel: ChatChannel<Custom.Channel>
  /// The associated `ChatUser` for this Member
  /// - Important:Only the identifier is used when interacting with PubNub Membership APIs.  To perform operations on this object you will need to call the corresponding PubNub User API.
  public var chatUser: ChatUser<Custom.User>
  /// The current state of the Member
  public var status: String?
  /// Last time the remote object was changed.
  public var updated: Date?
  /// Caching value that changes whenever the remote object changes.
  public var eTag: String?
  /// Custom object that can be stored with the Channel.
  public var custom: CustomProperties

  /// Presence data for the ``chatUser`` on the connected ``chatChannel``
  public var presence: MembershipPresence?
  
  public init(
    channel: ChatChannel<Custom.Channel>,
    user: ChatUser<Custom.User>,
    status: String? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    presence: MembershipPresence? = nil,
    custom: Custom.Member = Custom.Member()
  ) {
    self.chatChannel = channel
    self.chatUser = user
    self.custom = CustomProperties(custom: custom)
    self.status = status
    self.updated = updated
    self.eTag = eTag
    self.presence = presence
  }
  
  public init(
    channelId: String,
    userId: String,
    status: String? = nil,
    updated: Date? = nil,
    eTag: String? = nil,
    presence: MembershipPresence? = nil,
    custom: Custom.Member = Custom.Member()
  ) {
    self.init(
      channel: .init(id: channelId),
      user: .init(id: userId),
      status: status,
      updated: updated,
      eTag: eTag,
      presence: presence,
      custom: custom
    )
  }

  @available(*, deprecated, renamed: "init(channel:user:status:updated:eTag:presence:custom:)")
  public init(
    channel: ChatChannel<Custom.Channel>,
    member: ChatUser<Custom.User>
  ) {
    self.init(
      channel: channel,
      user: member
    )
  }
  
  // MARK: Dynamic Member Lookup
  
  /// Returns a binding to the resulting value of a given key path.
  /// - Parameter dynamicMember: A key path to a specific resulting value.
  /// - Returns: A new binding.
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Custom.Member, T>) -> T {
    get { custom.custom[keyPath: keyPath] }
    set { custom.custom[keyPath: keyPath] = newValue }
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
  /// Create a ``ChatMember`` from the provided `PubNubMembership`
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

  /// Object that can be used to apply an update to another ``ChatMember``
  public struct Patcher {
    /// The underlying `PubNubMembership` Patcher object
    public var pubnub: PubNubMembership.Patcher
    /// The unique identifier of the User associated with the Member
    public var userId: String { pubnub.userId }
    /// The unique identifier of the Channel associated with the Member
    public var channelId: String { pubnub.spaceId }
    /// The cache identifier of the change
    public var eTag: String { pubnub.eTag }
    /// The timestamp of the change
    public var updated: Date { pubnub.updated }
    
    public init(pubnub: PubNubMembership.Patcher) {
      self.pubnub = pubnub
    }
  }
  
  /// Apply the patch to this ``ChatMember`` instance
  /// - Parameter patcher: The patching changeset to apply
  /// - Returns: The patched ``ChatMember`` with updated fields or a copy of this instance if no change was able to be applied
  public func patch(_ patcher: Patcher) -> ChatMember<Custom> {
    guard patcher.pubnub.shouldUpdate(
      userId: chatUser.id, spaceId: chatChannel.id, eTag: eTag, lastUpdated: updated
    ) else {
      return self
    }
    
    var mutableSelf = self
    
    patcher.pubnub.apply(
      status: { mutableSelf.status = $0 },
      custom: { mutableSelf.custom = CustomProperties(flatJSON: $0?.flatJSON) },
      updated: { mutableSelf.updated = $0 },
      eTag: { mutableSelf.eTag = $0 }
    )
    
    return mutableSelf
  }
}

// MARK: - Presence

/// Presence information for a specific User on a specific Channel
public struct MembershipPresence: Hashable {
  /// Whether the User is "Active" on a given Chanel
  public var isPresent: Bool
  // TODO: Does this need to be a custom property Chat.Presence?
  /// State information associated with a User on a given Channel
  public var presenceState: OptionalChange<AnyJSON>

  /// Create an object that updates both the `isPresent` flag and `presenceState`
  public init(
    isPresent: Bool,
    presenceState: JSONCodable?
  ) {
    self.isPresent = isPresent
    if let presenceState = presenceState {
      self.presenceState = .some(presenceState.codableValue)
    } else {
      self.presenceState = .none
    }
  }

  /// Create an object that only updates the `isPresent` flag and ignores `presenceState`
  public init(
    isPresent: Bool
  ) {
    self.isPresent = isPresent
    self.presenceState = .noChange
  }
}

extension ChatMember {
  static func presenceMemberships(
    channelId: String, presence: PubNubPresence
  ) -> [ChatMember] {
    var memberships = [ChatMember]()
    
    // Create Presence Memberships for all Occupants
    for memberId in presence.occupants {
      memberships.append(ChatMember(
        channelId: channelId,
        userId: memberId,
        presence: .init(
          isPresent: true,
          presenceState: presence.occupantsState[memberId]
        )
      ))
    }

    // Determine if there are any UUIDs in `occupantsState` not in `occupants`
    for (memberId, state) in presence.occupantsState where !presence.occupants.contains(memberId) {
      memberships.append(ChatMember(
        channelId: channelId,
        userId: memberId,
        presence: .init(
          isPresent: true,
          presenceState: state
        )
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
          ChatMember(
            channelId: channelId,
            userId: $0,
            presence: .init(isPresent: true)
          )
        }
        memberships.append(contentsOf: joins)
      case .leave(uuids: let uuids), .timeout(uuids: let uuids):
        let leaves = uuids.map {
          ChatMember(channelId: channelId, userId: $0, presence: .init(isPresent: false))
        }
        memberships.append(contentsOf: leaves)
      case .stateChange(uuid: let uuid, state: let state):
        memberships.append(
          ChatMember(
            channelId: channelId,
            userId: uuid,
            presence: .init(
              isPresent: true,
              presenceState: state
            )
          )
        )
      }
    }
    
    return memberships
  }
}
