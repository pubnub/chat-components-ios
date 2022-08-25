//
//  ReactionProvider+Extension.swift
//  PubNubChat
//
//  Created by Maciej Adamczyk on 25/08/2022.
//

import Foundation

extension ReactionProvider {
  func makeMessageReactionComponents() -> [MessageReactionButtonComponent] {
    reactions.map {
      let result = MessageReactionButtonComponent(type: .custom)
      result.reaction = $0
      return result
    }
  }
}
