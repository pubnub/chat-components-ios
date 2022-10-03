//
//  MessageReactionListView.swift
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
import Combine

public class MessageReactionListComponent: UIView {
  private var reactionProvider: ReactionProvider
  private var reactionButtons: [MessageReactionButtonComponent] = []
  
  var currentCount: Int = 0
  
  public init(provider: ReactionProvider = DefaultReactionProvider()) {
    self.reactionProvider = provider
    
    super.init(frame: .zero)
    setupSubviews()
  }
  
  public required init?(coder: NSCoder) {
    self.reactionProvider = DefaultReactionProvider()
    
    super.init(coder: coder)
    setupSubviews()
  }
  
  lazy public var stackViewContainer = UIStackContainerView()

  var allReactions: [String] {
    reactionProvider.reactions
  }
  
  open func setupSubviews() {
    translatesAutoresizingMaskIntoConstraints = false
    
    stackViewContainer.stackView.alignment = .leading
    stackViewContainer.stackView.spacing = 5.0
    stackViewContainer.stackView.axis = .horizontal
    
    addSubview(stackViewContainer)
    stackViewContainer.translatesAutoresizingMaskIntoConstraints = false
    stackViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    stackViewContainer.topAnchor.constraint(equalTo: topAnchor).isActive = true
    
    stackViewContainer.trailingAnchor
      .constraint(equalTo: trailingAnchor)
      .priority(.overrideRequire).isActive = true
    stackViewContainer.bottomAnchor
      .constraint(equalTo: bottomAnchor)
      .priority(.overrideRequire).isActive = true
  }
  
  open func configure<Message>(
    _ messageActionButtons: [MessageReactionButtonComponent],
    message: Message,
    currentUserId: String,
    reactionProvider: ReactionProvider,
    onMessageActionTap: ((MessageReactionButtonComponent?, Message, (() -> Void)?) -> Void)?
  ) where Message : ManagedMessageViewModel {
    
    self.reactionProvider = reactionProvider
    
    let reactions = message.messageActions
      .filter { $0.sourceType == "reaction" }
      .map { (reaction: $0.value, userID: $0.pubnubUserId) }
    
    updateWith(reactions: reactions.map { $0.reaction } )
    
    reactionButtons.forEach { button in
      button.isSelected = reactions.contains(where: { $0.userID == currentUserId && $0.reaction == button.reaction })
    }
    
    reactionButtons.forEach { button in
      button.didTap({ [weak message] button in
        guard let message = message else { return }
        
        button?.isEnabled = false
        onMessageActionTap?(button, message) { [weak button] in
          DispatchQueue.main.async {
            button?.isEnabled = true
          }
        }
      })
      .store(in: &button.externalCancellables)
    }
  }

  open func configure<Message>(
    _ message: Message,
    currentUserId: String,
    reactionProvider: ReactionProvider,
    onMessageActionTap: ((MessageReactionButtonComponent?, Message, (() -> Void)?) -> Void)?
  ) where Message : ManagedMessageViewModel {
    configure(
      reactionButtons,
      message: message,
      currentUserId: currentUserId,
      reactionProvider: reactionProvider,
      onMessageActionTap: onMessageActionTap
    )
  }
  
  func button(for reaction: String) -> MessageReactionButtonComponent {
    if let button = reactionButtons.first(where: { $0.reaction == reaction }) {
      return button
    }
    
    let newButton = reactionProvider.makeMessageReactionComponentWith(reaction)
    reactionButtons.append(newButton)
    stackViewContainer.stackView.addArrangedSubview(newButton)
    
    setNeedsLayout()
    return newButton
  }
}

// MARK: - Private
private extension MessageReactionListComponent {
  private func makeCountsDictionary(with reactions: [String]) -> [String: Int] {
    Dictionary( reactions.map { ($0, 1) }, uniquingKeysWith: +)
  }
  
  private func update(with reaction: String, count: Int) {
    guard reactionProvider.reactions.contains(reaction) else { return }
    
    let button = button(for: reaction)
    button.externalCancellables.forEach { $0.cancel() }
    button.currentCount = count
    button.isHidden = false
  }
  
  private func removeUnusedButtons(for reactions: [String]) {
    var indexes = [Int]()
    reactionButtons.enumerated().forEach { (index, button) in
      if !reactions.contains (where: { $0 == button.reaction }) {
        button.removeFromSuperview()
        stackViewContainer.stackView.removeArrangedSubview(button)
        indexes.append(index)
      }
    }
    
    indexes.reversed().forEach {
      reactionButtons.remove(at: $0)
    }

    setNeedsLayout()
  }
  
  private func updateWith(reactions: [String]) {
    let counts = makeCountsDictionary(with: reactions)
    let countSum = counts.keys.reduce(0) { $0 + (counts[$1] ?? 0) }
    currentCount = countSum
    
    isHidden = countSum == 0

    removeUnusedButtons(for: reactions)
    
    counts.keys.forEach { reaction in
      if let count = counts[reaction] {
        update(with: reaction, count: count)
      }
    }
    
    stackViewContainer.layoutIfNeeded()
    layoutIfNeeded()
  }
}
