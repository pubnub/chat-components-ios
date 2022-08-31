//
//  ReactionProvider.swift
//  PubNubChat
//
//  Created by Maciej Adamczyk on 25/08/2022.
//

import Foundation

/// Use this protocol to implement own custom ReactionProvider, instead you can use DefaultReactionProvider or CustomReactionProvider
public protocol ReactionProvider {
  /// Provides list of available reactions
  var reactions: [String] { get }
}

extension ReactionProvider {
  func makeMessageReactionComponents() -> [MessageReactionButtonComponent] {
    reactions.map {
      let result = MessageReactionButtonComponent(type: .custom)
      result.reaction = $0
      return result
    }
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
