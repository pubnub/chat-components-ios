//
//  PubNubProvider.swift
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

public protocol ReactionProvider {
  var reactions: [String] { get }
}

extension ReactionProvider {
  func makeMessageReactionComponents() -> [MessageReactionButtonComponent] {
    reactions.map {
      makeMessageReactionComponentWith($0)
    }
  }
  
  func makeMessageReactionComponentWith(_ reaction: String) -> MessageReactionButtonComponent {
    let result = MessageReactionButtonComponent(type: .custom)
    result.reaction = reaction
    return result
  }
}


public struct DefaultReactionProvider: ReactionProvider {
  public let reactions: [String]
  
  public init() {
    reactions = ["👍", "❤️", "😂", "😲", "😢", "🔥"]
  }
}

public struct CustomReactionProvider: ReactionProvider {
  public let reactions: [String]
  
  public init(reactions: [String]) {
    self.reactions = reactions
  }
}
