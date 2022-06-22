//
//  Tests+ChannelAPI.swift
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
import PubNubSpace

class ChannelAPITests: XCTestCase {
  
  var mockPubNub = PubNubMock()
  
  lazy var provider = ChatProvider<ChatMockCustom, PubNubManagedChatEntities>(
    pubnubProvider: mockPubNub
  ).pubnubProvider
  
  var testChannel = PubNubSpace(
    id: "testChannelId",
    name: "testName",
    type: "testType",
    status: "testStatus",
    spaceDescription: "testDescription",
    custom: ChatChannel<ChannelMockCustom>.CustomProperties(
      avatarURL: URL(string: "https://example.com"),
      custom: ChatMockCustom.Channel(location: "testLocl", isHidden: true)
    ),
    updated: .distantPast,
    eTag: "testChannelId"
  )
  
  private var cancellables: Set<AnyCancellable>!
  
  override func setUp() {
    super.setUp()
    cancellables = []
  }
  
  // MARK: - Channel Request
  
  func testChatChannelRequest_init() {
    let chatChannel = ChatChannel<ChatMockCustom.Channel>(pubnub: testChannel)
    let testRequest = ChatChannelRequest<ChannelMockCustom>(
      channel: chatChannel,
      includeCustom: false,
      config: mockPubNub.configuration
    )
    
    XCTAssertEqual(testRequest.channel, chatChannel)
    XCTAssertEqual(testRequest.includeCustom, false)
    XCTAssertEqual(testRequest.config, mockPubNub.configuration)
  }
  
  // MARK: - PubNubSpaceAPI Default Impl.
  
  func testFetchChannels() {
    let expectation = XCTestExpectation(description: "Fetch Channels API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChannelsFetchRequest()
    mockPubNub.fetchSpacesRequest = {
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
    mockPubNub.fetchSpacesResponse = { [unowned self] in
      nextRequest.page = PubNub.Page(start: "next-key", end: "prev-key", totalCount: 100)
      return .success((spaces: [testChannel], next: nextRequest.page))
    }
    
    // Execute Tests
    provider.fetch(
      channels: testRequest,
      into: ChannelMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success((channels, next)):
        XCTAssertEqual(channels.first, .init(pubnub: testChannel))
        XCTAssertEqual(next, nextRequest)
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testFetchChannel() {
    let expectation = XCTestExpectation(description: "Fetch Channel API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChatChannelRequest<ChannelMockCustom>(channel: .init(pubnub: testChannel))
    mockPubNub.fetchSpaceRequest = { (channelId, includeCustom, requestConfig) in
      XCTAssertEqual(channelId, testRequest.channel.id)
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.singleSpaceResponse = { [unowned self] in
      return .success(testChannel)
    }
    
    // Execute Tests
    provider.fetch(
      channel: testRequest,
      into: ChannelMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success(channel):
        XCTAssertEqual(channel, .init(pubnub: testChannel))
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testCreateChannel() {
    let expectation = XCTestExpectation(description: "Create Channel API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChatChannelRequest<ChannelMockCustom>(channel: .init(pubnub: testChannel))
    mockPubNub.createSpaceRequest = {
      (channelId, name, type, status, description, custom, includeCustom, requestConfig) in
      
      XCTAssertEqual(channelId, testRequest.channel.id)
      XCTAssertEqual(name, testRequest.channel.name)
      XCTAssertEqual(type, testRequest.channel.type)
      XCTAssertEqual(status, testRequest.channel.status)
      XCTAssertEqual(description, testRequest.channel.details)
      XCTAssertEqual(custom?.codableValue, testRequest.channel.custom.codableValue)
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.singleSpaceResponse = { [unowned self] in
      return .success(testChannel)
    }
    
    // Execute Tests
    provider.create(
      channel: testRequest,
      into: ChannelMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success(channel):
        XCTAssertEqual(channel, .init(pubnub: testChannel))
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testUpdateChannel() {
    let expectation = XCTestExpectation(description: "Update Channel API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChatChannelRequest<ChannelMockCustom>(channel: .init(pubnub: testChannel))
    mockPubNub.createSpaceRequest = {
      (channelId, name, type, status, description, custom, includeCustom, requestConfig) in
      
      XCTAssertEqual(channelId, testRequest.channel.id)
      XCTAssertEqual(name, testRequest.channel.name)
      XCTAssertEqual(type, testRequest.channel.type)
      XCTAssertEqual(status, testRequest.channel.status)
      XCTAssertEqual(description, testRequest.channel.details)
      XCTAssertEqual(custom?.codableValue, testRequest.channel.custom.codableValue)
      XCTAssertEqual(includeCustom, testRequest.includeCustom)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.singleSpaceResponse = { [unowned self] in
      return .success(testChannel)
    }
    
    // Execute Tests
    provider.update(
      channel: testRequest,
      into: ChannelMockCustom.self
    ) { [unowned self] result in
      switch result {
        // Validate Output
      case let .success(channel):
        XCTAssertEqual(channel, .init(pubnub: testChannel))
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testRemoveChannel() {
    let expectation = XCTestExpectation(description: "Remove Channel API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChatChannelRequest<ChannelMockCustom>(channel: .init(pubnub: testChannel))
    mockPubNub.removeSpaceRequest = {
      (channelId, requestConfig) in
      
      XCTAssertEqual(channelId, testRequest.channel.id)
      XCTAssertEqual(requestConfig.customConfiguration as? PubNubConfiguration, testRequest.config)
      expectation.fulfill()
    }
    
    // Provider Output
    mockPubNub.voidResponse = {
      return .success(Void())
    }
    
    // Execute Tests
    provider.remove(
      channel: testRequest,
      into: ChannelMockCustom.self
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
  
  // MARK: - PubNubSpaceAPI Combine Impl.
  
  func testFetchPagesPublisher() {
    let expectation = XCTestExpectation(description: "Fetch Paginated Channels API")
    expectation.expectedFulfillmentCount = 4
    
    // Validate Input
    let testRequest = ChannelsFetchRequest()
    let nextPage = PubNub.Page(start: "next-key", end: "prev-key", totalCount: 100)
    mockPubNub.fetchSpacesRequest = {
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
    mockPubNub.fetchSpacesResponse = { [unowned self] in
      if let page = nextRequest.page {
        nextRequest.page = nil
        return .success((spaces: [testChannel], next: page))
      } else {
        return .success((spaces: [testChannel], next: nextRequest.page))
      }
    }
    
    provider.fetchPagesPublisher(
      channels: testRequest,
      into: ChannelMockCustom.self
    )
    .sink { completion in
      switch completion {
      case .finished:
        expectation.fulfill()
      case let .failure(error):
        XCTFail("Test failed with error \(error)")
      }
    } receiveValue: { [unowned self] (channels, next) in
      if let next = next {
        // Get First Page
        XCTAssertEqual(channels.first, .init(pubnub: testChannel))
        var nextRequest = nextRequest
        nextRequest.page = nextPage
        XCTAssertEqual(next, nextRequest)
      } else {
        // Last Page
        XCTAssertEqual(channels.first, .init(pubnub: testChannel))
      }
      expectation.fulfill()
    }
    .store(in: &cancellables)
    
    wait(for: [expectation], timeout: 1.0)
  }
  
  func testFetchPagesPublisher_Error() {
    let expectation = XCTestExpectation(description: "Fetch Paginated Channels API")
    expectation.expectedFulfillmentCount = 2
    
    // Validate Input
    let testRequest = ChannelsFetchRequest()
    mockPubNub.fetchSpacesRequest = {
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
    mockPubNub.fetchSpacesResponse = {
      return .failure(PubNubError.Reason.resourceNotFound)
    }
    
    provider.fetchPagesPublisher(
      channels: testRequest,
      into: ChannelMockCustom.self
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

