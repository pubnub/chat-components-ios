//
//  Tests+ChatUser.swift
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
import PubNubUser

class ChatUserTests: XCTestCase {
  func testUser_Codable() throws {
    let user = ChatUser(
      id: "testId",
      name: "testName",
      type: "testType",
      status: "testStatus",
      externalId: "testExternalId",
      avatarURL: URL(string: "https://example.com"),
      email: "testEmail",
      updated: .distantPast,
      eTag: "testETag",
      custom: UserMockCustom(location: "testLoc", isHidden: true)
    )
    
    let data = try Constant.jsonEncoder.encode(user)
    
    XCTAssertEqual(
      user, try Constant.jsonDecoder.decode(ChatUser<UserMockCustom>.self, from: data)
    )
  }
  
  func testUser_Codable_FromJSON() throws {
    let user = ChatUser(
      id: "testId",
      name: "testName",
      avatarURL: URL(string: "https://example.com"),
      custom: UserMockCustom(location: "here", isHidden: false)
    )
    
    let userJSON: [String: Any] = [
      "name": "testName",
      "id": "testId",
      "profileUrl": "https://example.com",
      "custom": [
        "location": "here",
        "isHidden": false
      ]
    ]
    
    XCTAssertEqual(
      user, try AnyJSON(userJSON).decode(ChatUser<UserMockCustom>.self)
    )
  }

  func testUser_DynamicMemberLookup_CustomFields() throws {
    var user = ChatUser(
      id: "testId",
      name: "testName",
      avatarURL: URL(string: "https://example.com"),
      custom: UserMockCustom(location: "here", isHidden: false)
    )
    
    XCTAssertEqual(user.location, "here")
    user.location = "new-loc"
    XCTAssertEqual(user.location, "new-loc")
  }

  func testCustomProperties_initFlatJSON() {
    let flatJSON: [String: JSONCodableScalar] = [
      "location": JSONCodableScalarType(stringValue: "here"),
      "isHidden": JSONCodableScalarType(boolValue: false)
    ]
    
    let custom = ChatUser<UserMockCustom>.CustomProperties(flatJSON: flatJSON)
    
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
    
    let custom = ChatUser<UserMockCustom>.CustomProperties()
    
    XCTAssertEqual(
      flatJSON.mapValues { $0.codableValue },
      custom.flatJSON.mapValues { $0.codableValue }
    )
  }
  
  func testUser_PubNubUser_Init() {
    let user = ChatUser(
      id: "testId",
      name: "testName",
      type: "testType",
      status: "testStatus",
      externalId: "testExternalId",
      avatarURL: URL(string: "https://example.com"),
      email: "testEmail",
      updated: .distantPast,
      eTag: "testETag",
      custom: UserMockCustom(location: "testLoc", isHidden: true)
    )
    
    let userFromSpace = ChatUser<UserMockCustom>(pubnub: .init(
      id: user.id,
      name: user.name,
      type: user.type,
      status: user.status,
      externalId: user.externalId,
      profileURL: user.avatarURL,
      email: user.email,
      custom: user.custom,
      updated: user.updated,
      eTag: user.eTag
    ))
    
    XCTAssertEqual(user, userFromSpace)
  }
  
  func testUserPatcher_patch_shouldUpdate_false() {
    let spacePatch = PubNubUser.Patcher(
      id: "patch-id", updated: .distantPast, eTag: "patch-eTag", name: .some("newName")
    )
    let userPatch = ChatUser<UserMockCustom>.Patcher(pubnub: spacePatch)
    
    let user = ChatUser(
      id: "testId",
      name: "testName",
      type: "testType",
      status: "testStatus",
      externalId: "testExternalId",
      avatarURL: URL(string: "https://example.com"),
      email: "testEmail",
      updated: .distantPast,
      eTag: "testETag",
      custom: UserMockCustom(location: "testLoc", isHidden: true)
    )
    
    XCTAssertEqual(user, user.patch(userPatch))
  }
  
  func testUserPatcher_patch_shouldUpdate_true() {
    let user = ChatUser(
      id: "testId",
      name: "testName",
      type: "testType",
      status: "testStatus",
      externalId: "testExternalId",
      avatarURL: URL(string: "https://example.com"),
      email: "testEmail",
      updated: .distantPast,
      eTag: "testETag",
      custom: UserMockCustom(location: "testLoc", isHidden: true)
    )
    
    let patchedUser = ChatUser(
      id: user.id,
      name: "patchedName",
      type: "patchedType",
      status: "patchedStatus",
      externalId: "patchedExternalId",
      avatarURL: URL(string: "https://patched.example.com"),
      email: "patchedEmail",
      updated: .distantFuture,
      eTag: "patchedETag",
      custom: UserMockCustom(location: "patchedLoc", isHidden: false)
    )
    
    let spacePatch = PubNubUser.Patcher(
      id: patchedUser.id,
      updated: patchedUser.updated  ?? .distantPast,
      eTag: patchedUser.eTag ?? "",
      name: .some(patchedUser.name ?? ""),
      type: .some(patchedUser.type),
      status: .some(patchedUser.status ?? ""),
      externalId: .some(patchedUser.externalId ?? ""),
      profileURL: .some(patchedUser.avatarURL!),
      email: .some(patchedUser.email ?? ""),
      custom: .some(patchedUser.custom)
    )
    let userPatch = ChatUser<UserMockCustom>.Patcher(pubnub: spacePatch)
    
    XCTAssertEqual(userPatch.id, patchedUser.id)
    XCTAssertEqual(userPatch.updated, patchedUser.updated)
    XCTAssertEqual(userPatch.eTag, patchedUser.eTag)
    XCTAssertEqual(patchedUser, user.patch(userPatch))
  }
}
