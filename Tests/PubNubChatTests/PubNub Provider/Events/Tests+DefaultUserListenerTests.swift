//
//  Tests+DefaultUserListener.swift
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

class DefaultUserListenerTests: XCTestCase {
  
  var provider = ChatProvider<ChatMockCustom, PubNubManagedChatEntities>(
    pubnubProvider: PubNubMock(),
    coreDataProvider: try! CoreDataProvider(location: .memory),
    cacheProvider: UserDefaults.standard
  )

  let testUser = ChatUser<UserMockCustom>(
    id: "TestUserId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    externalId: "TestExternalID",
    avatarURL: URL(string: "http://example.com"),
    email: "TestEmail",
    updated: Date.distantPast,
    eTag: "TestETag",
    custom: .init(location: "testLoc", isHidden: true)
  )

  override func setUp() async throws {
    PubNub.log.levels = .all
  }

  func testUserListener_userUpdated() throws {
    let expectation = XCTestExpectation(description: "User Updated Event")
    expectation.expectedFulfillmentCount = 2

    provider.coreDataContainer.syncWrite { [unowned self] context in
      let user = try PubNubManagedChatEntities.User.insert(user: testUser, into: context)
      XCTAssertEqual(user.convert(), testUser)
      expectation.fulfill()
    }
    
    var patchedUser = testUser
    patchedUser.name = "NewName"
    patchedUser.updated = .distantFuture
    patchedUser.eTag = "NewETag"

    let event = PubNubEntityEvent(
      source: "vsp",
      version: "2.0",
      action: .updated,
      type: .user,
      data: [
        "id": patchedUser.id,
        "name": patchedUser.name,
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": patchedUser.eTag
      ]
    )
    provider.dataProvider.userListener.emit(entity: [event])

    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSUpdatedObjectsKey] is Set<PubNubManagedUser> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.User.userBy(pubnubId: testUser.id)
        )

        XCTAssertEqual(result.first?.convert(), patchedUser)
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testUserListener_userRemoved() throws {
    let expectation = XCTestExpectation(description: "User Removed Event")
    expectation.expectedFulfillmentCount = 2
    
    let testUser = ChatUser<UserMockCustom>(
      id: "TestUserId",
      name: "TestName",
      type: "TestType",
      status: "TestStatus",
      externalId: "TestExternalID",
      avatarURL: URL(string: "http://example.com"),
      email: "TestEmail",
      updated: Date.distantPast,
      eTag: "TestETag",
      custom: .init(location: "testLoc", isHidden: true)
    )
    
    provider.coreDataContainer.syncWrite { context in
      let user = try PubNubManagedChatEntities.User.insert(user: testUser, into: context)
      XCTAssertEqual(user.convert(), testUser)
      expectation.fulfill()
    }
    
    let event = PubNubEntityEvent(
      source: "vsp",
      version: "2.0",
      action: .removed,
      type: .user,
      data: [
        "id": testUser.id,
        "name": testUser.name,
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": testUser.eTag
      ]
    )
    provider.dataProvider.userListener.emit(entity: [event])

    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSDeletedObjectsKey] is Set<PubNubManagedUser> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.User.userBy(pubnubId: testUser.id)
        )
        
        XCTAssertNil(result.first)
        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
