//
//  Tests+DefaultMembershipListener.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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
import Combine
import CoreData

@testable import PubNubChat
import PubNub
import PubNubUser

class DefaultMembershipListenerTests: XCTestCase {
  
  var provider = ChatProvider<ChatMockCustom, PubNubManagedChatEntities>(
    pubnubProvider: PubNubMock(),
    coreDataProvider: try! CoreDataProvider(location: .memory),
    cacheProvider: UserDefaults.standard
  )
  
  let testMember = ChatMember<ChatMockCustom>(
    channel: ChatChannel(id: "TestChannelId"),
    user: ChatUser(id: "TestUserId"),
    status: "TestStatus",
    updated: Date.distantPast,
    eTag: "TestETag",
    presence: .init(isPresent: false, presenceState: nil),
    custom: .init(location: "testLoc", isHidden: true)
  )
  
  override func setUp() async throws {
    PubNub.log.levels = .all
  }
  
  func testSpaceListener_membershipUpdated() throws {
    let expectation = XCTestExpectation(description: "Membership Updated Event")
    expectation.expectedFulfillmentCount = 2
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      let member = try PubNubManagedChatEntities.Member
        .insert(member: testMember, forceWrite: true, into: context)
      XCTAssertEqual(member.convert(), testMember)
      expectation.fulfill()
    }
    
    var patchedMember = testMember
    patchedMember.status = "NewStatus"
    patchedMember.updated = .distantFuture
    patchedMember.eTag = "NewETag"
    
    let event = PubNubEntityEvent(
      source: "vsp",
      version: "2.0",
      action: .updated,
      type: .membership,
      data: [
        "uuid": ["id": testMember.chatUser.id],
        "channel": ["id": testMember.chatChannel.id],
        "status": patchedMember.status,
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": patchedMember.eTag
      ]
    )
    provider.dataProvider.membershipListener.emit(entity: [event])
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSUpdatedObjectsKey] is Set<PubNubManagedMember> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.Member
            .memberBy(
              pubnubChannelId: testMember.chatChannel.id,
              pubnubUserId: testMember.chatUser.id
            )
        )
        
        XCTAssertEqual(result.first?.convert(), patchedMember)
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testSpaceListener_membershipRemoved() throws {
    let expectation = XCTestExpectation(description: "Membership Removed Event")
    expectation.expectedFulfillmentCount = 2
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      let member = try PubNubManagedChatEntities.Member
        .insert(member: testMember, forceWrite: true, into: context)
      XCTAssertEqual(member.convert(), testMember)
      expectation.fulfill()
    }
    
    let event = PubNubEntityEvent(
      source: "vsp",
      version: "2.0",
      action: .removed,
      type: .membership,
      data: [
        "uuid": ["id": testMember.chatUser.id],
        "channel": ["id": testMember.chatChannel.id],
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": testMember.eTag
      ]
    )
    provider.dataProvider.membershipListener.emit(entity: [event])
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSDeletedObjectsKey] is Set<PubNubManagedMember> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.Member
            .memberBy(
              pubnubChannelId: testMember.chatChannel.id,
              pubnubUserId: testMember.chatUser.id
            )
        )
        
        XCTAssertNil(result.first)
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
}

