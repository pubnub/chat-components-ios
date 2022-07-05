//
//  Tests+UserRequests.swift
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

extension UserAPITests {
  func testFetchEntitesRequest_init() {
    let testPage = PubNub.Page(next: "test-next", prev: "test-prev", totalCount: 8)
    let testRequest = UsersFetchRequest(
      includeCustom: false,
      includeTotalCount: true,
      limit: 10,
      filter: "testFilter",
      sort: [.name(ascending: true)],
      page: testPage,
      config: mockPubNub.configuration
    )
    
    XCTAssertEqual(testRequest.includeCustom, false)
    XCTAssertEqual(testRequest.includeTotalCount, true)
    XCTAssertEqual(testRequest.limit, 10)
    XCTAssertEqual(testRequest.filter, "testFilter")
    XCTAssertEqual(testRequest.sort, [.name(ascending: true)])
    XCTAssertEqual(testRequest.page, testPage)
    XCTAssertEqual(testRequest.config, mockPubNub.configuration)
  }
  
  func testFetchEntitesRequest_nextRequest() {
    let testRequest = UsersFetchRequest(
      page: .init(start: "test-next", end: "test-prev", totalCount: 8)
    )
    
    let nextPage = PubNub.Page(start: "new-next", end: "new-prev", totalCount: 10)
    var nextRequest = testRequest
    nextRequest.page = nextPage
    
    XCTAssertNotEqual(testRequest, nextRequest)
    XCTAssertEqual(testRequest.next(page: nextPage), nextRequest)
  }
  
  func testFetchEntitesRequest_nextRequest_nilStart() {
    let testRequest = UsersFetchRequest(
      page: .init(start: "test-next", end: "test-prev", totalCount: 8)
    )
    
    let nextPage = PubNub.Page(start: nil, end: "new-prev", totalCount: 10)
    
    XCTAssertNil(testRequest.next(page: nextPage))
  }
  
  func testFetchEntitesRequest_nextRequest_samePage() {
    let prevPage = PubNub.Page(start: "test-prev", end: "test-prev", totalCount: 10)
    let testRequest = UsersFetchRequest(
      sort: [.name(ascending: true)],
      page: prevPage
    )
    
    XCTAssertNil(testRequest.next(page: prevPage))
  }
  
  func testChatUserRequest_init() {
    let chatUser = ChatUser<ChatMockCustom.User>(pubnub: testUser)
    let testRequest = ChatUserRequest<UserMockCustom>(
      user: chatUser,
      includeCustom: false,
      config: mockPubNub.configuration
    )
    
    XCTAssertEqual(testRequest.user, chatUser)
    XCTAssertEqual(testRequest.includeCustom, false)
    XCTAssertEqual(testRequest.config, mockPubNub.configuration)
  }
}
