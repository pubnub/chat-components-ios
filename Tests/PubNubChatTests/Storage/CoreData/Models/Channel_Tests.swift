//
//  Channel_Tests.swift
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

struct ChannelMockCustom: ChannelCustomData {
  init() {
    location = "here"
    isHidden = false
  }
  
  init(flatJSON: [String : JSONCodableScalar]?) {
    location = flatJSON?["location"]?.scalarValue.stringOptional ?? String()
    isHidden = flatJSON?["isHidden"]?.scalarValue.boolOptional ?? false
  }
  
  var location: String
  var isHidden: Bool
}

class Channel_Tests: XCTestCase {
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testEncoder() throws {
    
    let channel = ChatChannel(
      id: "12341234",
      name: "Cool Channel",
      type: "default",
      custom: ChannelMockCustom()
    )

    let data = try Constant.jsonEncoder.encode(channel)
    let json = try Constant.jsonDecoder.decode(AnyJSON.self, from: data)
    
    print(json)
  }
  
  func testDecoder() throws {
    
    let json: [String: Any] = [
      "name": "Cool Place",
      "id":"1234123",
      "custom": [
        "location": "here",
        "isHidden": false,
        "type": "default"
      ]
    ]

    let chat = try AnyJSON(json).decode(ChatChannel<ChannelMockCustom>.self)
    
    print(chat)
  }
}
