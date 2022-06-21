//
//  Tests+UserAPI.swift
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

@testable import PubNubChat
import PubNub
import PubNubUser

class UserAPITests: XCTestCase {
  
  var mockPubNub = PubNubMock()
  
  lazy var provider = ChatProvider<ChatMockCustom, PubNubManagedChatEntities>(
    pubnubProvider: mockPubNub
  ).pubnubProvider
  
  var testUser = PubNubUser(
    id: "testUserId",
    name: "testName",
    type: "testType",
    status: "testStatus",
    externalId: "testExternalId",
    profileURL: URL(string: "https://example.com"),
    email: "testUserId",
    custom: ChatMockCustom.User(location: "testLocl", isHidden: true),
    updated: .distantPast,
    eTag: "testUserId"
  )

  private var cancellables: Set<AnyCancellable>!
  
  override func setUp() {
    super.setUp()
    cancellables = []
  }

  // MARK: - PubNubUserAPI Default Impl.

  func testFetchUsers() {
    let expectation = XCTestExpectation(description: "Fetch Users API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = UsersFetchRequest()
    mockPubNub.fetchUsersRequest = {
      (includeCustom, includeTotalCount, filter, sort, limit, page, requestConfig) in
      
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(includeTotalCount, testRequest.includeTotalCount)
      XCTAssertEqual(filter, testRequest.filter)
      XCTAssertEqual(sort, testRequest.sort)
      XCTAssertEqual(limit, testRequest.limit)
      XCTAssertEqual(page?.next, testRequest.page?.next)
      XCTAssertEqual(page?.prev, testRequest.page?.prev)
      XCTAssertEqual(page?.totalCount, testRequest.page?.totalCount)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    var nextRequest = testRequest
    mockPubNub.fetchUsersResponse = { [unowned self] in
      nextRequest.page = PubNub.Page(start: "next-key", end: "prev-key", totalCount: 100)
      return .success((users: [testUser], next: nextRequest.page))
    }

    // Execute Tests
    provider.fetch(
      users: testRequest,
      into: UserMockCustom.self
    ) { [unowned self] result in
      switch result {
      // Validate Output
      case let .success((users, next)):
        XCTAssertEqual(users.first, .init(pubnub: testUser))
        XCTAssertEqual(next, nextRequest)
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchUser() {
    let expectation = XCTestExpectation(description: "Fetch User API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChatUserRequest<UserMockCustom>(user: .init(pubnub: testUser))
    mockPubNub.fetchUserRequest = { (userId, includeCustom, requestConfig) in
      XCTAssertEqual(userId, testRequest.user.id)
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.singleUserResponse = { [unowned self] in
      return .success(testUser)
    }
    
    // Execute Tests
    provider.fetch(
      user: testRequest,
      into: UserMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success(user):
        XCTAssertEqual(user, .init(pubnub: testUser))
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testCreateUser() {
    let expectation = XCTestExpectation(description: "Create User API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChatUserRequest<UserMockCustom>(user: .init(pubnub: testUser))
    mockPubNub.createUserRequest = {
      (userId, name, type, status, externalId, profileUrl, email, custom, includeCustom, requestConfig) in

      XCTAssertEqual(userId, testRequest.user.id)
      XCTAssertEqual(name, testRequest.user.name)
      XCTAssertEqual(type, testRequest.user.type)
      XCTAssertEqual(status, testRequest.user.status)
      XCTAssertEqual(externalId, testRequest.user.externalId)
      XCTAssertEqual(profileUrl, testRequest.user.avatarURL)
      XCTAssertEqual(email, testRequest.user.email)
      XCTAssertEqual(custom?.codableValue, testRequest.user.custom.codableValue)
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.singleUserResponse = { [unowned self] in
      return .success(testUser)
    }
    
    // Execute Tests
    provider.create(
      user: testRequest,
      into: UserMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success(user):
        XCTAssertEqual(user, .init(pubnub: testUser))
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdateUser() {
    let expectation = XCTestExpectation(description: "Update User API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChatUserRequest<UserMockCustom>(user: .init(pubnub: testUser))
    mockPubNub.createUserRequest = {
      (userId, name, type, status, externalId, profileUrl, email, custom, includeCustom, requestConfig) in
      
      XCTAssertEqual(userId, testRequest.user.id)
      XCTAssertEqual(name, testRequest.user.name)
      XCTAssertEqual(type, testRequest.user.type)
      XCTAssertEqual(status, testRequest.user.status)
      XCTAssertEqual(externalId, testRequest.user.externalId)
      XCTAssertEqual(profileUrl, testRequest.user.avatarURL)
      XCTAssertEqual(email, testRequest.user.email)
      XCTAssertEqual(custom?.codableValue, testRequest.user.custom.codableValue)
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.singleUserResponse = { [unowned self] in
      return .success(testUser)
    }
    
    // Execute Tests
    provider.update(
      user: testRequest,
      into: UserMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success(user):
        XCTAssertEqual(user, .init(pubnub: testUser))
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testRemoveUser() {
    let expectation = XCTestExpectation(description: "Remove User API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChatUserRequest<UserMockCustom>(user: .init(pubnub: testUser))
    mockPubNub.removeUserRequest = {
      (userId, requestConfig) in
      
      XCTAssertEqual(userId, testRequest.user.id)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.voidResponse = {
      return .success(Void())
    }
    
    // Execute Tests
    provider.remove(
      user: testRequest,
      into: UserMockCustom.self
    ) { result in
      switch result {
        // Validate Output
      case .success:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - PubNubUserAPI Combine Impl.

  func testFetchPagesPublisher() {
    let expectation = XCTestExpectation(description: "Fetch Paginated Users API")
    expectation.expectedFulfillmentCount = 4
    
    // Validate Input
    let testRequest = UsersFetchRequest()
    let nextPage = PubNub.Page(start: "next-key", end: "prev-key", totalCount: 100)
    mockPubNub.fetchUsersRequest = {
      (includeCustom, includeTotalCount, filter, sort, limit, page, requestConfig) in
      
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(includeTotalCount, testRequest.includeTotalCount)
      XCTAssertEqual(filter, testRequest.filter)
      XCTAssertEqual(sort, testRequest.sort)
      XCTAssertEqual(limit, testRequest.limit)
      // Page from 2nd request
      if let page = page {
        XCTAssertEqual(page.next, nextPage.next)
        XCTAssertEqual(page.prev, nextPage.prev)
        XCTAssertEqual(page.totalCount, nextPage.totalCount)
      }
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    var nextRequest = testRequest
    nextRequest.page = nextPage
    mockPubNub.fetchUsersResponse = { [unowned self] in
      if let page = nextRequest.page {
        nextRequest.page = nil
        return .success((users: [testUser], next: page))
      } else {
        return .success((users: [testUser], next: nextRequest.page))
      }
    }

    provider.fetchPagesPublisher(
      users: testRequest,
      into: UserMockCustom.self
    )
      .sink { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case let .failure(error):
          XCTFail("Test failed with error \(error)")
        }
      } receiveValue: { [unowned self] (users, next) in
        if let next = next {
          // Get First Page
          XCTAssertEqual(users.first, .init(pubnub: testUser))
          var nextRequest = nextRequest
          nextRequest.page = nextPage
          XCTAssertEqual(next, nextRequest)
        } else {
          // Last Page
          XCTAssertEqual(users.first, .init(pubnub: testUser))
        }
        expectation.fulfill()
      }
      .store(in: &cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchPagesPublisher_Error() {
    let expectation = XCTestExpectation(description: "Fetch Paginated Users API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = UsersFetchRequest()
    mockPubNub.fetchUsersRequest = {
      (includeCustom, includeTotalCount, filter, sort, limit, page, requestConfig) in
      
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(includeTotalCount, testRequest.includeTotalCount)
      XCTAssertEqual(filter, testRequest.filter)
      XCTAssertEqual(sort, testRequest.sort)
      XCTAssertEqual(limit, testRequest.limit)
      XCTAssertEqual(page?.next, testRequest.page?.next)
      XCTAssertEqual(page?.prev, testRequest.page?.prev)
      XCTAssertEqual(page?.totalCount, testRequest.page?.totalCount)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.fetchUsersResponse = {
      return .failure(PubNubError.Reason.resourceNotFound)
    }
    
    provider.fetchPagesPublisher(
      users: testRequest,
      into: UserMockCustom.self
    )
    .sink { completion in
      switch completion {
      case .finished:
        XCTFail("Test should not finish successfully")
      case let .failure(error):
        XCTAssertEqual(error.request, testRequest)
        XCTAssertEqual(error.error as? PubNubError.Reason, .resourceNotFound)
        expectation.fulfill()
      }
    } receiveValue: { _ in
      XCTFail("Test should not have a successful request")
    }
    .store(in: &cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
}
