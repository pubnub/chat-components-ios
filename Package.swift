// swift-tools-version:5.3
//
//  Package.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright (c) 2013 PubNub Inc.
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
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright (c) 2013 PubNub Inc.
//  https://www.pubnub.com/
//  https://www.pubnub.com/terms
//

import Foundation
import PackageDescription

let package = Package(
  name: "chat-components-ios",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v13)
  ],
  products: [
    .library(
      name: "PubNubChat",
      targets: ["PubNubChat"]),
    .library(
      name: "PubNubChatComponents",
      targets: ["PubNubChatComponents"]
    )
  ],
  dependencies: [
    // Common
    .package(name: "PubNub", url: "https://github.com/pubnub/swift.git", from: "4.1.2"),
    
    // PubNubChat
    
    // PubNubChatComponents
    .package(name: "Kingfisher", url: "https://github.com/onevcat/Kingfisher.git", from: "6.3.0"),
    .package(name: "ChatLayout", url: "https://github.com/ekazaev/ChatLayout", from: "1.1.10"),
    .package(name: "InputBarAccessoryView", url: "https://github.com/nathantannar4/InputBarAccessoryView", from: "5.4.0")
  ],
  targets: [
    .target(
      name: "PubNubChat",
      dependencies: ["PubNub"],
      exclude: ["Info.plist"]
    ),
    .testTarget(
      name: "PubNubChatTests",
      dependencies: ["PubNubChat"],
      exclude: ["Info.plist"]
    ),
    .target(
      name: "PubNubChatComponents",
      dependencies: ["PubNubChat", "Kingfisher", "ChatLayout", "InputBarAccessoryView"],
      exclude: ["Info.plist"]
    )
  ]
)
