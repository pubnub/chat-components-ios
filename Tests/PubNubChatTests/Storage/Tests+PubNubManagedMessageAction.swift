//
//  Tests+PubNubManagedMessageAction.swift
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

class PubNubManagedMessageActionTests: XCTestCase {
  var provider = ChatProvider<ChatMockCustom, PubNubManagedChatEntities>(
    pubnubProvider: PubNubMock(),
    coreDataProvider: try! CoreDataProvider(location: .memory),
    cacheProvider: UserDefaults.standard
  )
  
  lazy var testMessage = PubNubChatMessage(
    content: .init(id: "AB1A55FC-CDDA-4693-97B1-3E24E66F4069", text: "Test Test Test"),
    timetoken: 1233,
    pubnubUserId: testUser.id,
    user: testUser,
    pubnubChannelId: testChannel.id,
    channel: testChannel
  )
  
  lazy var testMessageAction = PubNubChatMessageAction(
    actionTimetoken: 1234,
    parentTimetoken: testMessage.timetoken,
    sourceType: "reaction",
    value: "👍",
    pubnubUserId: testUser.id,
    pubnubChannelId: testChannel.id
  )
  
  let testChannel = PubNubChatChannel(
    id: "testChannelId",
    name: "testChannel",
    type: "test",
    avatarURL: URL(string: "https://example.com"),
    updated: .distantPast,
    eTag: "testChannelEtag"
  )

  let testUser = PubNubChatUser(
    id: "testUserId",
    name: "testUser",
    avatarURL: URL(string: "https://example.com"),
    updated: .distantPast,
    eTag: "testUserEtag"
  )

  let otherTestUser = PubNubChatUser(
    id: "otherTestUserId",
    name: "otherTestUser",
    avatarURL: URL(string: "https://example.com"),
    updated: .distantPast,
    eTag: "otherTestUserEtag"
  )
  
  override func setUp() async throws {
    PubNub.log.levels = .all
  }

  // MARK: Context Init
  
  func testMessageActionInitContext_PassingRelationships() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 2
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSInsertedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionBy(messageAction: testMessageAction)
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          XCTAssertEqual(action, testMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      let user = try PubNubManagedChatEntities.User
        .insert(user: testUser, into: context)
      XCTAssertEqual(user.convert(), testUser)
      
      let message = try PubNubManagedChatEntities.Message
        .insert(message: testMessage, into: context)
      XCTAssertEqual(message.id, testMessage.id)
      
      let _ = try PubNubManagedMessageAction(
        chat: testMessageAction,
        parent: message,
        author: user,
        context: context
      )
      
      expectation.fulfill()
    }
  }
  
  func testMessageActionInitContext_ExistingRelationships() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 3
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      let user = try PubNubManagedChatEntities.User
        .insert(user: testUser, into: context)
      XCTAssertEqual(user.convert(), testUser)
      
      let message = try PubNubManagedChatEntities.Message
        .insert(message: testMessage, into: context)
      XCTAssertEqual(message.id, testMessage.id)
      
      expectation.fulfill()
    }
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSInsertedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionBy(messageAction: testMessageAction)
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          XCTAssertEqual(action, testMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      let _ = try PubNubManagedMessageAction(
        chat: testMessageAction,
        context: context
      )
      
      expectation.fulfill()
    }
  }
  
  func testMessageActionInitContext_NestedRelationships() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 3
    
    var otherMessageAction = testMessageAction
    otherMessageAction.pubnubUserId = otherTestUser.id
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSInsertedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionBy(messageAction: otherMessageAction)
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          otherMessageAction.messageModel = nil
          otherMessageAction.userModel = nil
          XCTAssertEqual(action, otherMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      otherMessageAction.messageModel = testMessage
      otherMessageAction.userModel = otherTestUser
      
      let _ = try PubNubManagedMessageAction(
        chat: otherMessageAction,
        context: context
      )
      
      expectation.fulfill()
    }
  }
  
  func testMessageActionInitContext_Error_MissingUserData() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    
    var otherMessageAction = testMessageAction
    otherMessageAction.pubnubUserId = otherTestUser.id
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      let message = try PubNubManagedChatEntities.Message
        .insert(message: testMessage, into: context)
      XCTAssertEqual(message.id, testMessage.id)
      
      XCTAssertThrowsError(try PubNubManagedMessageAction(
        chat: otherMessageAction,
        parent: message,
        context: context
      ))
      
      expectation.fulfill()
    }
  }
  
  func testMessageActionInitContext_Error_MissingMessageData() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      let user = try PubNubManagedChatEntities.User
        .insert(user: testUser, into: context)
      XCTAssertEqual(user.convert(), testUser)
      
      XCTAssertThrowsError(try PubNubManagedMessageAction(
        chat: testMessageAction,
        author: user,
        context: context
      ))
      
      expectation.fulfill()
    }
  }


  // MARK: Update

  func testUpdateMessageAction() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 3

    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      let messageAction = try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context)
      testMessageAction.messageModel = nil
      XCTAssertEqual(messageAction.id, testMessageAction.id)

      expectation.fulfill()
    }
    
    var updatedMessageAction = testMessageAction
    updatedMessageAction.value = "newValue"
    XCTAssertNotEqual(updatedMessageAction, testMessageAction)
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSUpdatedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionBy(messageAction: updatedMessageAction)
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          XCTAssertEqual(action, updatedMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { context in
      let _ = try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: updatedMessageAction, into: context)
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdateMessageAction_UpdateNested() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 3
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      let messageAction = try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context)
      testMessageAction.messageModel = nil
      XCTAssertEqual(messageAction.id, testMessageAction.id)
      
      expectation.fulfill()
    }
    
    var updatedUser = testUser
    updatedUser.name = "updatedName"
    XCTAssertNotEqual(updatedUser, testUser)
    
    var updatedMessage = testMessage
    updatedMessage.text = "nextText"
    XCTAssertNotEqual(updatedMessage, testMessage)
    
    var updatedMessageAction = testMessageAction
    updatedMessageAction.value = "newValue"
    XCTAssertNotEqual(updatedMessageAction, testMessageAction)

    updatedMessageAction.messageModel = updatedMessage
    updatedMessageAction.userModel = updatedUser

    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSUpdatedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionBy(messageAction: updatedMessageAction)
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          updatedMessageAction.userModel = nil
          updatedMessageAction.messageModel = nil
          XCTAssertEqual(action, updatedMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { context in
      let _ = try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: updatedMessageAction, into: context)
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  // MARK: Remove
  func testRemoveMessageAction() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 3
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      let messageAction = try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context)
      testMessageAction.messageModel = nil
      XCTAssertEqual(messageAction.id, testMessageAction.id)
      
      expectation.fulfill()
    }
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSDeletedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionBy(messageAction: testMessageAction)
        )
        
        XCTAssertTrue(result.isEmpty)
        
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      XCTAssertNotNil(PubNubManagedChatEntities.MessageAction
        .remove(messageActionId: testMessageAction.id, from: context))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testRemoveMessageAction_NothingToRemove() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")

    provider.coreDataContainer.syncWrite { context in
      XCTAssertNil(PubNubManagedChatEntities.MessageAction
        .remove(messageActionId: "MissingMessageActionid", from: context))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: Fetches

  func testFetchMessageAction_ActionsByUserId() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 2

    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSInsertedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionsBy(pubnubUserId: testMessageAction.pubnubUserId)
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          testMessageAction.userModel = nil
          testMessageAction.messageModel = nil
          XCTAssertEqual(action, testMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      XCTAssertNotNil(try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchMessageAction_ActionsByParentTimetoken() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 2
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSInsertedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionsBy(
            messageTimetoken: testMessageAction.parentTimetoken,
            channelId: testMessageAction.pubnubChannelId
          )
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          testMessageAction.userModel = nil
          testMessageAction.messageModel = nil
          XCTAssertEqual(action, testMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      XCTAssertNotNil(try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchMessageAction_ActionsByParentId() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 2
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSInsertedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionsBy(
            messageId: testMessage.id
          )
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          testMessageAction.userModel = nil
          testMessageAction.messageModel = nil
          XCTAssertEqual(action, testMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      XCTAssertNotNil(try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchMessageAction_ActionsByChatMessageAction() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 2
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSInsertedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionBy(
            messageAction: testMessageAction
          )
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          testMessageAction.userModel = nil
          testMessageAction.messageModel = nil
          XCTAssertEqual(action, testMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      XCTAssertNotNil(try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchMessageAction_ActionsByChatMessageActionId() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    expectation.expectedFulfillmentCount = 2
    
    NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: provider.coreDataContainer.mutableBackgroundContext,
      queue: .main
    ) { [unowned self] notification in
      if notification.userInfo?[NSInsertedObjectsKey] is Set<NSManagedObject> {
        let result = try! provider.coreDataContainer.viewContext.fetch(
          PubNubManagedChatEntities.MessageAction.messageActionBy(
            messageActionId: testMessageAction.id
          )
        )
        do {
          let action: ChatMessageAction<VoidCustomData>? = try result.first?.convert()
          testMessageAction.userModel = nil
          testMessageAction.messageModel = nil
          XCTAssertEqual(action, testMessageAction)
        } catch {
          XCTFail("Test failed due to error \(error)")
        }
        expectation.fulfill()
      }
    }
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      XCTAssertNotNil(try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context))
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: ManagedMessageAction Entity

  func testManagedMessageActionEntity_ComputedProperties() throws {
    let expectation = XCTestExpectation(description: "Message Action Update Expectation")
    
    provider.coreDataContainer.syncWrite { [unowned self] context in
      testMessageAction.messageModel = testMessage
      let messageAction = try PubNubManagedChatEntities.MessageAction
        .insertOrUpdate(messageAction: testMessageAction, into: context)
      
      XCTAssertEqual(messageAction.pubnubActionTimetoken, messageAction.published)
      XCTAssertEqual(messageAction.managedUser, messageAction.author)
      XCTAssertEqual(messageAction.managedMessage, messageAction.parent)

      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
}
