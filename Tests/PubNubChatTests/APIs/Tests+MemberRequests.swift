//
//  Tests+MemberRequests.swift
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

extension MemberAPITests {
  func testUserMemberFetchRequest_init() {
    let testPage = PubNub.Page(next: "test-next", prev: "test-prev", totalCount: 8)
    let testRequest = UserMemberFetchRequest(
      channelId: "testChannelId",
      includeCustom: false,
      includeTotalCount: true,
      includeUserFields: false,
      filter: "testFilter",
      sort: [.status(ascending: true)],
      limit: 10,
      page: testPage,
      config: mockPubNub.configuration
    )
    
    XCTAssertEqual(testRequest.channelId, "testChannelId")
    XCTAssertEqual(testRequest.includeCustom, false)
    XCTAssertEqual(testRequest.includeTotalCount, true)
    XCTAssertEqual(testRequest.includeUserFields, false)
    XCTAssertEqual(testRequest.limit, 10)
    XCTAssertEqual(testRequest.filter, "testFilter")
    XCTAssertEqual(testRequest.sort, [.status(ascending: true)])
    XCTAssertEqual(testRequest.page, testPage)
    XCTAssertEqual(testRequest.config, mockPubNub.configuration)
  }
  
  func testUserMemberFetchRequest_nextPage() {
    let testRequest = UserMemberFetchRequest(
      channelId: "testChannelId",
      page: .init(start: "test-next", end: "test-prev", totalCount: 8)
    )
    
    let nextPage = PubNub.Page(start: "new-next", end: "new-prev", totalCount: 10)
    var nextRequest = testRequest
    nextRequest.page = nextPage
    
    XCTAssertNotEqual(testRequest, nextRequest)
    XCTAssertEqual(testRequest.next(page: nextPage), nextRequest)
  }
  
  func testUserMemberFetchRequest_nextPage_nilStart() {
    let testRequest = UserMemberFetchRequest(
      channelId: "testChannelId",
      page: .init(start: "test-next", end: "test-prev", totalCount: 8)
    )
    
    let nextPage = PubNub.Page(start: nil, end: "new-prev", totalCount: 10)
    
    XCTAssertNil(testRequest.next(page: nextPage))
  }
  
  func testUserMemberFetchRequest_nextPage_samePage() {
    let prevPage = PubNub.Page(start: "test-prev", end: "test-prev", totalCount: 10)
    let testRequest = UserMemberFetchRequest(
      channelId: "testChannelId",
      page: prevPage
    )
    
    XCTAssertNil(testRequest.next(page: prevPage))
  }
  
  func testChannelMemberFetchRequest_init() {
    let testPage = PubNub.Page(next: "test-next", prev: "test-prev", totalCount: 8)
    let testRequest = ChannelMemberFetchRequest(
      userId: "testUserId",
      includeCustom: false,
      includeTotalCount: true,
      includeChannelFields: false,
      filter: "testFilter",
      sort: [.status(ascending: true)],
      limit: 10,
      page: testPage,
      config: mockPubNub.configuration
    )
    
    XCTAssertEqual(testRequest.userId, "testUserId")
    XCTAssertEqual(testRequest.includeCustom, false)
    XCTAssertEqual(testRequest.includeTotalCount, true)
    XCTAssertEqual(testRequest.includeChannelFields, false)
    XCTAssertEqual(testRequest.limit, 10)
    XCTAssertEqual(testRequest.filter, "testFilter")
    XCTAssertEqual(testRequest.sort, [.status(ascending: true)])
    XCTAssertEqual(testRequest.page, testPage)
    XCTAssertEqual(testRequest.config, mockPubNub.configuration)
  }
  
  func testChannelMemberFetchRequest_nextPage() {
    let testRequest = ChannelMemberFetchRequest(
      userId: "testUserId",
      page: .init(start: "test-next", end: "test-prev", totalCount: 8)
    )
    
    let nextPage = PubNub.Page(start: "new-next", end: "new-prev", totalCount: 10)
    var nextRequest = testRequest
    nextRequest.page = nextPage
    
    XCTAssertNotEqual(testRequest, nextRequest)
    XCTAssertEqual(testRequest.next(page: nextPage), nextRequest)
  }
  
  func testChannelMemberFetchRequest_nextPage_nilStart() {
    let testRequest = ChannelMemberFetchRequest(
      userId: "testUserId",
      page: .init(start: "test-next", end: "test-prev", totalCount: 8)
    )
    
    let nextPage = PubNub.Page(start: nil, end: "new-prev", totalCount: 10)
    
    XCTAssertNil(testRequest.next(page: nextPage))
  }
  
  func testChannelMemberFetchRequest_nextPage_samePage() {
    let prevPage = PubNub.Page(start: "test-prev", end: "test-prev", totalCount: 10)
    let testRequest = ChannelMemberFetchRequest(
      userId: "testUserId",
      page: prevPage
    )
    
    XCTAssertNil(testRequest.next(page: prevPage))
  }
  
  func testMembersModifyRequest_init() {
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyChannelsByUser,
      config: mockPubNub.configuration
    )
    
    XCTAssertEqual(testRequest.members, [])
    XCTAssertEqual(testRequest.modificationDirection, .modifyChannelsByUser)
    XCTAssertEqual(testRequest.config, mockPubNub.configuration)
  }
  
  func testMembersModifyRequest_channelPartials() {
    let chatMember = ChatMember<ChatMockCustom>(
      channelId: "testChannelId",
      userId: "testUserId",
      status: "testStatus",
      custom: .init(location: "testLoc", isHidden: false)
    )
    
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [chatMember],
      modificationDirection: .modifyChannelsByUser,
      config: mockPubNub.configuration
    )
    
    XCTAssertEqual(testRequest.channelPartials?.userId, chatMember.chatUser.id)
    XCTAssertEqual(
      testRequest.channelPartials?.partials,
      [.init(spaceId: chatMember.chatChannel.id, status: chatMember.status, custom: chatMember.custom)]
    )
  }
  
  func testMembersModifyRequest_channelPartials_emptyMembersList() {
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyChannelsByUser,
      config: mockPubNub.configuration
    )
    
    XCTAssertNil(testRequest.channelPartials)
  }
  
  func testMembersModifyRequest_userPartials() {
    
    
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [testChatMember],
      modificationDirection: .modifyChannelsByUser,
      config: mockPubNub.configuration
    )
    
    XCTAssertEqual(testRequest.userPartials?.channelId, testChatMember.chatChannel.id)
    XCTAssertEqual(
      testRequest.userPartials?.partials,
      [.init(userId: testChatMember.chatUser.id, status: testChatMember.status, custom: testChatMember.custom)]
    )
  }
  
  func testMembersModifyRequest_userPartials_emptyMembersList() {
    let testRequest = MembersModifyRequest<ChatMockCustom>(
      members: [],
      modificationDirection: .modifyChannelsByUser,
      config: mockPubNub.configuration
    )
    
    XCTAssertNil(testRequest.userPartials)
  }
}
