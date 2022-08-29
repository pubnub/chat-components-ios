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
      makeMessageReactionComponentWith($0)
    }
  }
  
  func makeMessageReactionComponentWith(_ reaction: String) -> MessageReactionButtonComponent {
    //probably we should check if reaction is possible!
    
    let result = MessageReactionButtonComponent(type: .custom)
    result.reaction = reaction
    return result
  }
}
