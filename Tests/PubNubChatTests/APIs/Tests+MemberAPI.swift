//
//  Tests+MemberAPI.swift
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
import PubNubSpace
import PubNubMembership

class MemberAPITests: XCTestCase {
  
  var mockPubNub = PubNubMock()
  
  lazy var provider = ChatProvider<ChatMockCustom, PubNubManagedChatEntities>(
    pubnubProvider: mockPubNub
  ).pubnubProvider

  var testMembership = PubNubMembership(
    user: .init(id: "testUserId"),
    space: .init(id: "testSpaceId"),
    status: "testStatus",
    custom: ChatMockCustom.Member(location: "testLocl", isHidden: true),
    updated: .distantPast,
    eTag: "testUserId"
  )

  lazy var testChatMember = ChatMember<ChatMockCustom>(
    channelId: testMembership.space.id,
    userId: testMembership.user.id,
    status: testMembership.status,
    updated: testMembership.updated,
    eTag: testMembership.eTag,
    custom: .init(flatJSON: testMembership.custom?.flatJSON)
  )
  
  private var cancellables: Set<AnyCancellable>!
  
  override func setUp() {
    super.setUp()
    cancellables = []
  }

  // MARK: - PubNub Member API Default Impl.

  func testFetchUserMembers() {
    let expectation = XCTestExpectation(description: "Fetch Members API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = UserMemberFetchRequest(
      channelId: testChatMember.chatChannel.id,
      sort: [.status(ascending: true)]
    )
    mockPubNub.fetchMembershipsRequest = {
      (channelId, includeCustom, includeTotalCount, filter, _, sort, limit, page, requestConfig) in
      
      XCTAssertEqual(channelId, testRequest.channelId)
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
    mockPubNub.fetchMembershipsResponse = { [unowned self] in
      nextRequest.page = PubNub.Page(start: "next-key", end: "prev-key", totalCount: 100)
      return .success((memberships: [testMembership], next: nextRequest.page))
    }
    
    // Execute Tests
    provider.fetch(
      userMembers: testRequest,
      into: ChatMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success((members, next)):
        XCTAssertEqual(members.first, .init(pubnub: testMembership))
        XCTAssertEqual(next, nextRequest)
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testFetchChannelMembers() {
    let expectation = XCTestExpectation(description: "Fetch Members API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChannelMemberFetchRequest(
      userId: testChatMember.chatUser.id,
      sort: [.status(ascending: true)]
    )
    mockPubNub.fetchMembershipsRequest = {
      (userId, includeCustom, includeTotalCount, filter, sort, _, limit, page, requestConfig) in
      
      XCTAssertEqual(userId, testRequest.userId)
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
    mockPubNub.fetchMembershipsResponse = { [unowned self] in
      nextRequest.page = PubNub.Page(start: "next-key", end: "prev-key", totalCount: 100)
      return .success((memberships: [testMembership], next: nextRequest.page))
    }
    
    // Execute Tests
    provider.fetch(
      channelMembers: testRequest,
      into: ChatMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success((members, next)):
        XCTAssertEqual(members.first, .init(pubnub: testMembership))
        XCTAssertEqual(next, nextRequest)
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testCreateMembers_ChannelsByUser() {
    let expectation = XCTestExpectation(description: "Create Members API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [testChatMember],
      modificationDirection: .modifyChannelsByUser,
      config: mockPubNub.configuration
    )
    mockPubNub.addSpacesByUserMembershipsRequest = {
      (channels, userId, requestConfig) in
      
      let memberPartial = testRequest.channelPartials
      XCTAssertEqual(channels, memberPartial?.partials)
      XCTAssertEqual(userId, memberPartial?.userId)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.voidResponse = {
      return .success(Void())
    }
    
    // Execute Tests
    provider.create(
      members: testRequest,
      into: ChatMockCustom.self
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

  func testCreateMembers_ChannelsByUser_MissingRequiredData() {
    let expectation = XCTestExpectation(description: "Create Members API")
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyChannelsByUser
    )
    
    // Execute Tests
    provider.create(
      members: testRequest,
      into: ChatMockCustom.self
    ) { result in
      switch result {
        // Validate Output
      case .success:
        XCTFail("Success received when it should fail")
      case let .failure(error):
        XCTAssertEqual(error as? ChatError, .missingRequiredData)
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testCreateMembers_UsersByChannel() {
    let expectation = XCTestExpectation(description: "Create Members API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [testChatMember],
      modificationDirection: .modifyUsersByChannel,
      config: mockPubNub.configuration
    )
    mockPubNub.addUsersBySpaceMembershipsRequest = {
      (users, channelId, requestConfig) in
      
      let memberPartial = testRequest.userPartials
      XCTAssertEqual(users, memberPartial?.partials)
      XCTAssertEqual(channelId, memberPartial?.channelId)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.voidResponse = {
      return .success(Void())
    }
    
    // Execute Tests
    provider.create(
      members: testRequest,
      into: ChatMockCustom.self
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
  
  func testCreateMembers_UsersByChannel_MissingRequiredData() {
    let expectation = XCTestExpectation(description: "Create Members API")
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyUsersByChannel
    )
    
    // Execute Tests
    provider.create(
      members: testRequest,
      into: ChatMockCustom.self
    ) { result in
      switch result {
        // Validate Output
      case .success:
        XCTFail("Success received when it should fail")
      case let .failure(error):
        XCTAssertEqual(error as? ChatError, .missingRequiredData)
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testUpdateMembers_ChannelsByUser() {
    let expectation = XCTestExpectation(description: "Update Members API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [testChatMember],
      modificationDirection: .modifyChannelsByUser,
      config: mockPubNub.configuration
    )
    mockPubNub.addSpacesByUserMembershipsRequest = {
      (channels, userId, requestConfig) in
      
      let memberPartial = testRequest.channelPartials
      XCTAssertEqual(channels, memberPartial?.partials)
      XCTAssertEqual(userId, memberPartial?.userId)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.voidResponse = {
      return .success(Void())
    }
    
    // Execute Tests
    provider.update(
      members: testRequest,
      into: ChatMockCustom.self
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
  
  func testUpdateMembers_ChannelsByUser_MissingRequiredData() {
    let expectation = XCTestExpectation(description: "Update Members API")
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyChannelsByUser
    )
    
    // Execute Tests
    provider.update(
      members: testRequest,
      into: ChatMockCustom.self
    ) { result in
      switch result {
        // Validate Output
      case .success:
        XCTFail("Success received when it should fail")
      case let .failure(error):
        XCTAssertEqual(error as? ChatError, .missingRequiredData)
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testUpdateMembers_UsersByChannel() {
    let expectation = XCTestExpectation(description: "Update Members API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [testChatMember],
      modificationDirection: .modifyUsersByChannel,
      config: mockPubNub.configuration
    )
    mockPubNub.addUsersBySpaceMembershipsRequest = {
      (users, channelId, requestConfig) in
      
      let memberPartial = testRequest.userPartials
      XCTAssertEqual(users, memberPartial?.partials)
      XCTAssertEqual(channelId, memberPartial?.channelId)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.voidResponse = {
      return .success(Void())
    }
    
    // Execute Tests
    provider.update(
      members: testRequest,
      into: ChatMockCustom.self
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
  
  func testUpdateMembers_UsersByChannel_MissingRequiredData() {
    let expectation = XCTestExpectation(description: "Update Members API")
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyUsersByChannel
    )
    
    // Execute Tests
    provider.update(
      members: testRequest,
      into: ChatMockCustom.self
    ) { result in
      switch result {
        // Validate Output
      case .success:
        XCTFail("Success received when it should fail")
      case let .failure(error):
        XCTAssertEqual(error as? ChatError, .missingRequiredData)
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  func testRemoveMembers_ChannelsByUser() {
    let expectation = XCTestExpectation(description: "Remove Members API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [testChatMember],
      modificationDirection: .modifyChannelsByUser,
      config: mockPubNub.configuration
    )
    mockPubNub.removeSpacesFromUserMembershipsRequest = {
      (channelIds, userId, requestConfig) in
      
      let memberPartial = testRequest.channelPartials
      XCTAssertEqual(channelIds, memberPartial?.partials.map { $0.space.id })
      XCTAssertEqual(userId, memberPartial?.userId)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.voidResponse = {
      return .success(Void())
    }
    
    // Execute Tests
    provider.remove(
      members: testRequest,
      into: ChatMockCustom.self
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
  
  func testRemoveMembers_ChannelsByUser_MissingRequiredData() {
    let expectation = XCTestExpectation(description: "Remove Members API")
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyChannelsByUser
    )
    
    // Execute Tests
    provider.remove(
      members: testRequest,
      into: ChatMockCustom.self
    ) { result in
      switch result {
        // Validate Output
      case .success:
        XCTFail("Success received when it should fail")
      case let .failure(error):
        XCTAssertEqual(error as? ChatError, .missingRequiredData)
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testRemoveMembers_UsersByChannel() {
    let expectation = XCTestExpectation(description: "Remove Members API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [testChatMember],
      modificationDirection: .modifyUsersByChannel,
      config: mockPubNub.configuration
    )
    mockPubNub.removeUsersFromSpaceMembershipsRequest = {
      (userIds, channelId, requestConfig) in
      
      let memberPartial = testRequest.userPartials
      XCTAssertEqual(userIds, memberPartial?.partials.map { $0.user.id })
      XCTAssertEqual(channelId, memberPartial?.channelId)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.voidResponse = {
      return .success(Void())
    }
    
    // Execute Tests
    provider.remove(
      members: testRequest,
      into: ChatMockCustom.self
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
  
  func testRemoveMembers_UsersByChannel_MissingRequiredData() {
    let expectation = XCTestExpectation(description: "Remove Members API")
    
    // Validate Input
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyUsersByChannel
    )
    
    // Execute Tests
    provider.remove(
      members: testRequest,
      into: ChatMockCustom.self
    ) { result in
      switch result {
        // Validate Output
      case .success:
        XCTFail("Success received when it should fail")
      case let .failure(error):
        XCTAssertEqual(error as? ChatError, .missingRequiredData)
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }

  // MARK: - PubNub Member API Combine Impl.

  func testFetchPagesPublisher_UserMembers() {
    let expectation = XCTestExpectation(description: "Fetch Paginated Member API")
    expectation.expectedFulfillmentCount = 4
    
    // Validate Input
    let testRequest = UserMemberFetchRequest(
      channelId: testChatMember.chatChannel.id
    )
    let nextPage = PubNub.Page(start: "next-key", end: "prev-key", totalCount: 100)
    mockPubNub.fetchMembershipsRequest = {
      (channelId, includeCustom, includeTotalCount, filter, _, sort, limit, page, requestConfig) in
      
      XCTAssertEqual(channelId, testRequest.channelId)
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
    mockPubNub.fetchMembershipsResponse = { [unowned self] in
      if let page = nextRequest.page {
        nextRequest.page = nil
        return .success((memberships: [testMembership], next: page))
      } else {
        return .success((memberships: [testMembership], next: nextRequest.page))
      }
    }
    
    provider.fetchPagesPublisher(
      userMembers: testRequest,
      into: ChatMockCustom.self
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
        XCTAssertEqual(users.first, .init(pubnub: testMembership))
        var nextRequest = nextRequest
        nextRequest.page = nextPage
        XCTAssertEqual(next, nextRequest)
      } else {
        // Last Page
        XCTAssertEqual(users.first, .init(pubnub: testMembership))
      }
      expectation.fulfill()
    }
    .store(in: &cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testFetchPagesPublisher_UserMembers_Error() {
    let expectation = XCTestExpectation(description: "Fetch Paginated Member API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = UserMemberFetchRequest(
      channelId: testChatMember.chatChannel.id
    )
    mockPubNub.fetchMembershipsRequest = {
      (channelId, includeCustom, includeTotalCount, filter, _, sort, limit, page, requestConfig) in
      
      XCTAssertEqual(channelId, testRequest.channelId)
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
    mockPubNub.fetchMembershipsResponse = {
      return .failure(PubNubError.Reason.resourceNotFound)
    }
    
    provider.fetchPagesPublisher(
      userMembers: testRequest,
      into: ChatMockCustom.self
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

  func testFetchPagesPublisher_ChannelMembers() {
    let expectation = XCTestExpectation(description: "Fetch Paginated Member API")
    expectation.expectedFulfillmentCount = 4
    
    // Validate Input
    let testRequest = ChannelMemberFetchRequest(
      userId: testChatMember.chatUser.id,
      sort: [.status(ascending: true)]
    )
    let nextPage = PubNub.Page(start: "next-key", end: "prev-key", totalCount: 100)
    mockPubNub.fetchMembershipsRequest = {
      (userId, includeCustom, includeTotalCount, filter, sort, _, limit, page, requestConfig) in
      
      XCTAssertEqual(userId, testRequest.userId)
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
    mockPubNub.fetchMembershipsResponse = { [unowned self] in
      if let page = nextRequest.page {
        nextRequest.page = nil
        return .success((memberships: [testMembership], next: page))
      } else {
        return .success((memberships: [testMembership], next: nextRequest.page))
      }
    }
    
    provider.fetchPagesPublisher(
      channelMembers: testRequest,
      into: ChatMockCustom.self
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
        XCTAssertEqual(users.first, .init(pubnub: testMembership))
        var nextRequest = nextRequest
        nextRequest.page = nextPage
        XCTAssertEqual(next, nextRequest)
      } else {
        // Last Page
        XCTAssertEqual(users.first, .init(pubnub: testMembership))
      }
      expectation.fulfill()
    }
    .store(in: &cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testFetchPagesPublisher_ChannelMembers_Error() {
    let expectation = XCTestExpectation(description: "Fetch Paginated Member API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChannelMemberFetchRequest(
      userId: testChatMember.chatUser.id
    )
    mockPubNub.fetchMembershipsRequest = {
      (userId, includeCustom, includeTotalCount, filter, sort, _, limit, page, requestConfig) in
      
      XCTAssertEqual(userId, testRequest.userId)
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
    mockPubNub.fetchMembershipsResponse = {
      return .failure(PubNubError.Reason.resourceNotFound)
    }
    
    provider.fetchPagesPublisher(
      channelMembers: testRequest,
      into: ChatMockCustom.self
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
