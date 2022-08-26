//
//  ReactionProvider.swift
//  PubNubChat
//
//  Created by Maciej Adamczyk on 25/08/2022.
//

import Foundation

public protocol ReactionProvider {
  var reactions: [String] { get }
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
