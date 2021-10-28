//
//  TypingIndicatorService.swift
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
import CoreData
import Combine

import PubNub

open class TypingIndicatorService {
  
  public static let shared = TypingIndicatorService()
  private init() { /* no-op */ }
  
  public struct Indicator: Hashable {
    public var channelId: String
    public var userId: String
    
    public var typingStatus: Date?
    
    public init(
      channelId: String,
      userId: String,
      typingStatus: Date? = Date()
    ) {
      self.channelId = channelId
      self.userId = userId
      self.typingStatus = typingStatus
    }
    
    public func isValid(for timeout: TimeInterval) -> Bool {
      guard let date = typingStatus else { return false }
      return date.distance(to: Date()) < timeout
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(channelId)
      hasher.combine(userId)
    }
    
    public static func ==(lhs: Indicator, rhs: Indicator) -> Bool {
      return lhs.channelId == rhs.channelId &&
        lhs.userId == rhs.userId
    }
  }

  /// The duration (in seconds) until an Indicator is considered timed out
  public var typingTimeout: TimeInterval = 6.0
  /// The interval (in seconds) that typing keep-alive will be published
  public var typingHeartbeat: TimeInterval = 3.0
  
  @Published public private(set) var typingMembers = [String: Set<Indicator>]()
  
  var timeoutTimers = [Indicator: Timer]()

  open func updateTypingStatus(channelId: String, userId: String, typingStatus: Date?) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      let indicator = Indicator(channelId: channelId, userId: userId, typingStatus: typingStatus)

      if self.typingMembers[indicator.channelId] == nil {
        self.typingMembers[indicator.channelId] = Set<Indicator>()
      }
      
      if typingStatus != nil {
        self.typingMembers[indicator.channelId]?.update(with: indicator)
        self.timeoutTimers[indicator]?.invalidate()
        
        self.timeoutTimers[indicator] = Timer.scheduledTimer(
          withTimeInterval: self.typingTimeout,
          repeats: false,
          block: { [weak self] timer in
            self?.updateTypingStatus(channelId: channelId, userId: userId, typingStatus: nil)
          }
        )

      } else {
        self.remove(typingIndicator: indicator)
      }
    }
  }
  
  open func remove(typingIndicator indicator: Indicator) {
    self.typingMembers[indicator.channelId]?.remove(indicator)
    self.timeoutTimers[indicator]?.invalidate()
    self.timeoutTimers.removeValue(forKey: indicator)
  }

  open func publisher(for channelId: String) -> AnyPublisher<Set<String>, Never> {
    let timeout = typingTimeout
    
    return $typingMembers
      .compactMap { $0[channelId]?.validUserIds(timeout) }
      .eraseToAnyPublisher()
  }
}

extension Set where Element == TypingIndicatorService.Indicator {
  func validUserIds(_ timeout: TimeInterval) -> Set<String> {
    return Set<String>(self.lazy.compactMap({ $0.isValid(for: timeout) ? $0.userId : nil }))
  }
}

