//
//  Tests+ChatChannel.swift
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
@testable import PubNub
import PubNubSpace

class ChatChannelTests: XCTestCase {
  func testChannel_Codable() throws {
    let channel = ChatChannel(
      id: "testId",
      name: "testName",
      type: "testType",
      status: "testStatus",
      details: "testDetails",
      avatarURL: URL(string: "https://example.com"),
      updated: .distantPast,
      eTag: "testETag",
      custom: ChannelMockCustom(location: "testLoc", isHidden: true)
    )

    let data = try Constant.jsonEncoder.encode(channel)
    
    XCTAssertEqual(
      channel, try Constant.jsonDecoder.decode(ChatChannel<ChannelMockCustom>.self, from: data)
    )
  }
  
  func testChannel_Codable_FromJSON() throws {
    let channel = ChatChannel(
      id: "testId",
      name: "testName",
      avatarURL: URL(string: "https://example.com"),
      custom: ChannelMockCustom(location: "here", isHidden: false)
    )
    
    let channelJSON: [String: Any] = [
      "name": "testName",
      "id": "testId",
      "custom": [
        "location": "here",
        "isHidden": false,
        "profileUrl": "https://example.com"
      ]
    ]
    
    XCTAssertEqual(
      channel, try AnyJSON(channelJSON).decode(ChatChannel<ChannelMockCustom>.self)
    )
  }

  func testChannel_DynamicMemberLookup_PubNubFields() throws {
    var channel = ChatChannel(
      id: "testId",
      name: "testName",
      avatarURL: URL(string: "https://example.com"),
      custom: ChannelMockCustom(location: "here", isHidden: false)
    )

    XCTAssertEqual(channel.avatarURL, URL(string: "https://example.com"))

    channel.avatarURL = URL(string: "https://new.example.com")
    XCTAssertEqual(channel.avatarURL, URL(string: "https://new.example.com"))
  }

  func testChannel_DynamicMemberLookup_CustomFields() throws {
    var channel = ChatChannel(
      id: "testId",
      name: "testName",
      avatarURL: URL(string: "https://example.com"),
      custom: ChannelMockCustom(location: "here", isHidden: false)
    )
    
    XCTAssertEqual(channel.location, "here")
    channel.location = "new-loc"
    XCTAssertEqual(channel.location, "new-loc")
  }

  func testCustomProperties_initFlatJSON() {
    let flatJSON: [String: JSONCodableScalar] = [
      "profileUrl": JSONCodableScalarType(stringValue: "https://example.com"),
      "location": JSONCodableScalarType(stringValue: "here"),
      "isHidden": JSONCodableScalarType(boolValue: false)
    ]

    let custom = ChatChannel<ChannelMockCustom>.CustomProperties(flatJSON: flatJSON)

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
    
    let custom = ChatChannel<ChannelMockCustom>.CustomProperties()
    
    XCTAssertEqual(
      flatJSON.mapValues { $0.codableValue },
      custom.flatJSON.mapValues { $0.codableValue }
    )
  }

  func testCustomProperties_flatJSON_Duplicate() {
    let flatJSON: [String: JSONCodableScalar] = [
      "profileUrl": JSONCodableScalarType(stringValue: "https://custom.example.com")
    ]
    
    let custom = ChatChannel<ChannelDuplicateMockCustom>.CustomProperties(
      avatarURL: URL(string: "https://example.com"),
      custom: .init(profileUrl: URL(string: "https://custom.example.com"))
    )

    XCTAssertEqual(
      flatJSON.mapValues { $0.codableValue },
      custom.flatJSON.mapValues { $0.codableValue }
    )
  }

  func testChannel_PubNubSpace_Init() {
    let channel = ChatChannel(
      id: "testId",
      name: "testName",
      type: "testType",
      status: "testStatus",
      details: "testDetails",
      avatarURL: URL(string: "https://example.com"),
      updated: .distantPast,
      eTag: "testETag",
      custom: ChannelMockCustom(location: "testLoc", isHidden: true)
    )

    let channelFromSpace = ChatChannel<ChannelMockCustom>(pubnub: .init(
      id: channel.id,
      name: channel.name,
      type: channel.type,
      status: channel.status,
      spaceDescription: channel.details,
      custom: channel.custom,
      updated: channel.updated,
      eTag: channel.eTag
    ))

    XCTAssertEqual(channel, channelFromSpace)
  }

  func testChannel_PubNubSpace_Init_CustomType() throws {
    let channelJSON: [String: Any] = [
      "id": "testId",
      "name": "testName",
      "custom": [
        "type": "some-other-type"
      ]
    ]

    let space = try AnyJSON(channelJSON).decode(PubNubSpace.self)
    
    let channel = ChatChannel<ChannelMockCustom>(
      id: "testId",
      name: "testName",
      type: "some-other-type"
    )
    
    XCTAssertEqual(channel, ChatChannel<ChannelMockCustom>(pubnub: space))
  }

  func testChannelPatcher_patch_shouldUpdate_false() {
    let spacePatch = PubNubSpace.Patcher(
      id: "patch-id", updated: .distantPast, eTag: "patch-eTag", name: .some("newName")
    )
    let channelPatch = ChatChannel<ChannelMockCustom>.Patcher(pubnub: spacePatch)

    let channel = ChatChannel(
      id: "testId",
      name: "testName",
      type: "testType",
      status: "testStatus",
      details: "testDetails",
      avatarURL: URL(string: "https://example.com"),
      updated: .distantPast,
      eTag: "testETag",
      custom: ChannelMockCustom(location: "testLoc", isHidden: true)
    )

    XCTAssertEqual(channel, channel.patch(channelPatch))
  }

  func testChannelPatcher_patch_shouldUpdate_true() {
    let channel = ChatChannel(
      id: "testId",
      name: "testName",
      type: "testType",
      status: "testStatus",
      details: "testDetails",
      avatarURL: URL(string: "https://example.com"),
      updated: .distantPast,
      eTag: "testETag",
      custom: ChannelMockCustom(location: "testLoc", isHidden: true)
    )

    let patchedChannel = ChatChannel(
      id: channel.id,
      name: "patchedName",
      type: "patchedType",
      status: "patchedStatus",
      details: "patchedDetails",
      avatarURL: URL(string: "https://patched.example.com"),
      updated: .distantFuture,
      eTag: "patchedETag",
      custom: ChannelMockCustom(location: "patchedLoc", isHidden: false)
    )

    let spacePatch = PubNubSpace.Patcher(
      id: patchedChannel.id,
      updated: patchedChannel.updated  ?? .distantPast,
      eTag: patchedChannel.eTag ?? "",
      name: .some(patchedChannel.name ?? ""),
      type: .some(patchedChannel.type),
      status: .some(patchedChannel.status ?? ""),
      spaceDescription: .some(patchedChannel.details ?? ""),
      custom: .some(patchedChannel.custom)
    )
    let channelPatch = ChatChannel<ChannelMockCustom>.Patcher(pubnub: spacePatch)

    XCTAssertEqual(channelPatch.id, patchedChannel.id)
    XCTAssertEqual(channelPatch.updated, patchedChannel.updated)
    XCTAssertEqual(channelPatch.eTag, patchedChannel.eTag)
    XCTAssertEqual(patchedChannel, channel.patch(channelPatch))
  }
}
