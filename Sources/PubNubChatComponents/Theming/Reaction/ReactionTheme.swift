//
//  ReactionTheme.swift
//  PubNubChat
//
//  Created by Maciej Adamczyk on 31/08/2022.
//

import UIKit

public struct ReactionTheme {
  public var reactions: [String] {
    provider.reactions
  }
  
  public let provider: ReactionProvider
  public let pickerMaxWidth: CGFloat
  
  public init(reactions: [String], maxWidth: CGFloat = 300) {
    provider = CustomReactionProvider(reactions: reactions)
    pickerMaxWidth = maxWidth
  }
  
  public init(provider: ReactionProvider = DefaultReactionProvider(), maxWidth: CGFloat = 300) {
    self.provider = provider
    pickerMaxWidth = maxWidth
  }
}
