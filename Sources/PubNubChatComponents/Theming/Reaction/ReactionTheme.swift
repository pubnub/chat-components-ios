//
//  ReactionTheme.swift
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

import UIKit

/// A structure that is capable of configuring reaction list and maximum width of MessageReactionComponent
public struct ReactionTheme {
  public var reactions: [String] {
    provider.reactions
  }
  
  public let provider: ReactionProvider
  public let pickerMaxWidth: CGFloat
  
  /// - Parameters:
  ///   - reactions: reaction list.
  ///   - maxWidth: maximum picker width.
  public init(reactions: [String], maxWidth: CGFloat = 300) {
    provider = CustomReactionProvider(reactions: reactions)
    pickerMaxWidth = maxWidth
  }
  
  /// - Parameters:
  ///   - provider: object providing list of symbols
  ///   - maxWidth: maximum picker width.
  public init(provider: ReactionProvider = DefaultReactionProvider(), maxWidth: CGFloat = 300) {
    self.provider = provider
    pickerMaxWidth = maxWidth
  }
}
