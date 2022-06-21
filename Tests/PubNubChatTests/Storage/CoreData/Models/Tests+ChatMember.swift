//
//  Tests+ChatMember.swift
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

import XCTest
@testable import PubNubChat
import PubNub
import PubNubMembership
import PubNubUser
import PubNubSpace

class ChatMemberTests: XCTestCase {
  func testMember_Codable() throws {
    let user = ChatUser<ChatMockCustom.User>(id: "Test User ID")
    let channel = ChatChannel<ChatMockCustom.Channel>(id: "Test Channel ID")
    
    let member = ChatMember<ChatMockCustom>(
      channel: channel,
      user: user,
      status: "Test Status",
      updated: .distantPast,
      eTag: "Test eTag",
      custom: MemberMockCustom(location: "testLoc", isHidden: true)
    )
    
    let data = try Constant.jsonEncoder.encode(member)
    
    XCTAssertEqual(
      member, try Constant.jsonDecoder.decode(ChatMember<ChatMockCustom>.self, from: data)
    )
  }

  func testMember_Codable_NilUserChannel() throws {
    let member = ChatMember<ChatMockCustom>(
      channelId: "Test Channel Id",
      userId: "Test User Id",
      status: "Test Status",
      eTag: "Test eTag"
    )
    
    let data = try Constant.jsonEncoder.encode(member)
    
    XCTAssertEqual(
      member, try Constant.jsonDecoder.decode(ChatMember<ChatMockCustom>.self, from: data)
    )
    XCTAssertFalse(member.chatUser.isSynced)
    XCTAssertFalse(member.chatChannel.isSynced)
    XCTAssertFalse(member.isSynced)
  }

  func testMember_Codable_FromJSON() throws {
    let member = ChatMember<ChatMockCustom>(
      channelId: "testChannelId",
      userId: "testUserId",
      status: "testStatus"
    )

    let memberJSON: [String: Any] = [
      "channel": ["id": "testChannelId"],
      "uuid": ["id": "testUserId"],
      "status": "testStatus"
    ]

    XCTAssertEqual(
      member, try AnyJSON(memberJSON).decode(ChatMember<ChatMockCustom>.self)
    )
  }

  func testMember_computed_ids() {
    let member = ChatMember<ChatMockCustom>(
      channelId: "Test Channel Id",
      userId: "Test User Id"
    )

    XCTAssertEqual(member.id, "\(member.chatChannel.id):\(member.chatUser.id)")
  }

  func testUser_DynamicMemberLookup_CustomFields() throws {
    var member = ChatMember<ChatMockCustom>(
      channelId: "Test Channel Id",
      userId: "Test User Id",
      custom: ChatMockCustom.Member(location: "here", isHidden: false)
    )
    
    XCTAssertEqual(member.location, "here")
    member.location = "new-loc"
    XCTAssertEqual(member.location, "new-loc")
  }

  func testCustomProperties_initFlatJSON() {
    let flatJSON: [String: JSONCodableScalar] = [
      "location": JSONCodableScalarType(stringValue: "here"),
      "isHidden": JSONCodableScalarType(boolValue: false)
    ]
    
    let custom = ChatMember<ChatMockCustom>.CustomProperties(flatJSON: flatJSON)
    
    XCTAssertEqual(
      flatJSON.mapValues { $0.codableValue },
      custom.flatJSON.mapValues { $0.codableValue }
    )
  }

  func testCustomProperties_initDefaultable() {
    let flatJSON: [String: JSONCodableScalar] = [
      "location": JSONCodableScalarType(stringValue: "here"),
      "isHidden": JSONCodableScalarType(boolValue: false)
    ]
    
    let custom = ChatMember<ChatMockCustom>.CustomProperties()
    
    XCTAssertEqual(
      flatJSON.mapValues { $0.codableValue },
      custom.flatJSON.mapValues { $0.codableValue }
    )
  }

  func testMember_PubNubMembership_Init() {
    let member = ChatMember<ChatMockCustom>(
      channelId: "Test Channel Id",
      userId: "Test User Id",
      status: "Test Status",
      updated: .distantPast,
      eTag: "Test eTag"
    )

    let membership = PubNubMembership(
      user: .init(id: member.chatUser.id),
      space: .init(id: member.chatChannel.id),
      status: member.status,
      updated: member.updated,
      eTag: member.eTag
    )

    XCTAssertEqual(member, ChatMember<ChatMockCustom>(pubnub: membership))
  }

  func testMemberPatcher_patch_shouldUpdate_false() {
    let membershipPatch = PubNubMembership.Patcher(
      userId: "patch-userId", spaceId: "patch-spaceId",
      updated: .distantPast, eTag: "patch-eTag", status: .some("newStatus")
    )
    let memberPatch = ChatMember<ChatMockCustom>.Patcher(pubnub: membershipPatch)
    
    let member = ChatMember<ChatMockCustom>(
      channel: .init(id: "patch-spaceId"),
      user: .init(id: "patch-userId"),
      status: "testStatus",
      updated: .distantPast,
      eTag: "testETag",
      custom: ChatMockCustom.Member(location: "testLoc", isHidden: true)
    )
    
    XCTAssertEqual(member, member.patch(memberPatch))
  }
  
  func testMemberPatcher_patch_shouldUpdate_true() {
    let member = ChatMember<ChatMockCustom>(
      channel: .init(id: "patch-spaceId"),
      user: .init(id: "patch-userId"),
      status: "testStatus",
      updated: .distantPast,
      eTag: "testETag",
      custom: ChatMockCustom.Member(location: "testLoc", isHidden: true)
    )
    
    let patchedMember = ChatMember<ChatMockCustom>(
      channel: .init(id: "patch-spaceId"),
      user: .init(id: "patch-userId"),
      status: "patchedStatus",
      updated: .distantFuture,
      eTag: "patchedETag",
      custom: ChatMockCustom.Member(location: "patchedLoc", isHidden: false)
    )
    
    let membershipPatch = PubNubMembership.Patcher(
      userId: patchedMember.chatUser.id,
      spaceId: patchedMember.chatChannel.id,
      updated: patchedMember.updated  ?? .distantPast,
      eTag: patchedMember.eTag ?? "",
      status: .some(patchedMember.status ?? ""),
      custom: .some(patchedMember.custom)
    )
    let memberPatch = ChatMember<ChatMockCustom>.Patcher(pubnub: membershipPatch)
    
    XCTAssertEqual(memberPatch.userId, patchedMember.chatUser.id)
    XCTAssertEqual(memberPatch.channelId, patchedMember.chatChannel.id)
    XCTAssertEqual(memberPatch.updated, patchedMember.updated)
    XCTAssertEqual(memberPatch.eTag, patchedMember.eTag)
    XCTAssertEqual(patchedMember, member.patch(memberPatch))
  }

  func testMember_Presence_PubNubPresence() {
    let member = ChatMember<ChatMockCustom>(
      channelId: "channelId",
      userId: "userId",
      presence: .init(isPresent: true, presenceState: nil)
    )

    let otherMember = ChatMember<ChatMockCustom>(
      channelId: "channelId",
      userId: "otherUser",
      presence: .init(isPresent: true, presenceState: ["key": "value"])
    )

    let presence = PubNubPresenceBase(
      channel: "channelId",
      occupancy: 100,
      occupants: ["userId"],
      occupantsState: ["otherUser": ["key": "value"]]
    )

    let members = ChatMember<ChatMockCustom>
      .presenceMemberships(channelId: presence.channel, presence: presence)

    XCTAssertEqual(members, [member,otherMember])
  }

  func testMember_Presence_ChangeActions() {
    let joinMember = ChatMember<ChatMockCustom>(
      channelId: "channelId",
      userId: "joinUserId",
      presence: .init(isPresent: true)
    )

    let leaveMember = ChatMember<ChatMockCustom>(
      channelId: "channelId",
      userId: "leaveUserId",
      presence: .init(isPresent: false)
    )

    let stateMember = ChatMember<ChatMockCustom>(
      channelId: "channelId",
      userId: "stateUserId",
      presence: .init(isPresent: true, presenceState: ["key": "value"])
    )

    let actions: [PubNubPresenceChangeAction] = [
      .join(uuids: ["joinUserId"]),
      .leave(uuids: ["leaveUserId"]),
      .stateChange(uuid: "stateUserId", state: ["key": "value"])
    ]
    
    let members = ChatMember<ChatMockCustom>
      .presenceMemberships(channelId: "channelId", changeActions: actions)

    XCTAssertEqual(members, [joinMember, leaveMember, stateMember])
  }
}
