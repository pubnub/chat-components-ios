//
//  Tests+DefaultChannelListener.swift
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

class DefaultSpaceListenerTests: XCTestCase {
  
  var provider = ChatProvider<ChatMockCustom, PubNubManagedChatEntities>(
    pubnubProvider: PubNubMock(),
    coreDataProvider: try! CoreDataProvider(location: .memory),
    cacheProvider: UserDefaults.standard
  )

  let testChannel = ChatChannel<ChannelMockCustom>(
    id: "TestUserId",
    name: "TestName",
    type: "TestType",
    status: "TestStatus",
    details: "TestPurpose",
    avatarURL: URL(string: "http://example.com"),
    updated: Date.distantPast,
    eTag: "TestETag",
    custom: .init(location: "testLoc", isHidden: true)
  )

  override func setUp() async throws {
    PubNub.log.levels = .all
  }

  func testSpaceListener_spaceUpdated() throws {
    let expectation = XCTestExpectation(description: "Space Updated Event")
    expectation.expectedFulfillmentCount = 2

    provider.coreDataContainer.syncWrite { [unowned self] context in
      let channel = try PubNubManagedChatEntities.Channel
        .insert(channel: testChannel, into: context)
      XCTAssertEqual(channel.convert(), testChannel)
      expectation.fulfill()
    }
    
    var patchedChannel = testChannel
    patchedChannel.name = "NewName"
    patchedChannel.updated = .distantFuture
    patchedChannel.eTag = "NewETag"
    
    let event = PubNubEntityEvent(
      source: "vsp",
      version: "2.0",
      action: .updated,
      type: .space,
      data: [
        "id": patchedChannel.id,
        "name": patchedChannel.name,
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": patchedChannel.eTag
      ]
    )
    provider.dataProvider.spaceListener.emit(entity: [event])
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSUpdatedObjectsKey] is Set<PubNubManagedChannel> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.Channel.channelBy(pubnubId: testChannel.id)
        )
        
        XCTAssertEqual(result.first?.convert(), patchedChannel)
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testSpaceListener_spaceRemoved() throws {
    let expectation = XCTestExpectation(description: "Space Removed Event")
    expectation.expectedFulfillmentCount = 2
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      let channel = try PubNubManagedChatEntities.Channel
        .insert(channel: testChannel, into: context)
      XCTAssertEqual(channel.convert(), testChannel)
      expectation.fulfill()
    }
    
    let event = PubNubEntityEvent(
      source: "vsp",
      version: "2.0",
      action: .removed,
      type: .space,
      data: [
        "id": testChannel.id,
        "name": testChannel.name,
        "updated": "4001-01-01T00:00:00.000Z",
        "eTag": testChannel.eTag
      ]
    )
    provider.dataProvider.spaceListener.emit(entity: [event])
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSDeletedObjectsKey] is Set<PubNubManagedChannel> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.Channel.channelBy(pubnubId: testChannel.id)
        )
        
        XCTAssertNil(result.first)
        expectation.fulfill()
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
}
