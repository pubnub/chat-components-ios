//
//  SubscribeAPI.swift
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

import Foundation

import PubNub

public struct SubscribeRequest: Codable {
  public var channels: [String]
  public var channelGroups: [String]
  public var timetoken: Timetoken?
  public var withPresence: Bool

  public init(
    channels: [String] = [],
    channelGroups: [String] = [],
    timetoken: Timetoken? = nil,
    withPresence: Bool = false
  ) {
    self.channels = channels
    self.channelGroups = channelGroups
    self.timetoken = timetoken
    self.withPresence = withPresence
  }
}

public struct UnsubscribeRequest: Codable {
  public var channels: [String]
  public var channelGroups: [String]
  public var withPresence: Bool
  
  public init(
    channels: [String] = [],
    channelGroups: [String] = [],
    withPresence: Bool = false
  ) {
    self.channels = channels
    self.channelGroups = channelGroups
    self.withPresence = withPresence
  }
}

// MARK: - PubNubAPI API

public protocol SubscribeAPI {
  func subscribe(_ request: SubscribeRequest)
  func reconnect(at: Timetoken?)
  func disconnect()

  var previousTimetoken: Timetoken? { get }

  func unsubscribe(_ request: UnsubscribeRequest)
  func unsubscribeAll()

  func add(_ listener: SubscriptionListener)
}

// MARK: - PubNub Ext

extension PubNub: SubscribeAPI {
  public func subscribe(_ request: SubscribeRequest) {
    subscribe(
      to: request.channels,
      and: request.channelGroups,
      at: request.timetoken ?? 0,
      withPresence: request.withPresence
    )
  }
  
  public func unsubscribe(_ request: UnsubscribeRequest) {
    unsubscribe(
      from: request.channels,
      and: request.channelGroups,
      presenceOnly: request.withPresence
    )
  }
}
