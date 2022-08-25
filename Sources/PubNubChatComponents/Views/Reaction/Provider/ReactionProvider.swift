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

public final class DefaultReactionProvider: ReactionProvider {
  public let reactions: [String]
  
  public init() {
    reactions = ["👍", "❤️", "😂", "😲", "😢", "🔥"]
  }
}

public final class CustomReactionProvider: ReactionProvider {
  public let reactions: [String]
  
  public init(reactions: [String]) {
    self.reactions = reactions
  }
}
