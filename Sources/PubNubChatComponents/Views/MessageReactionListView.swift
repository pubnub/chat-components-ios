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

public class MessageReactionListComponent: UIStackContainerView {

  // 👍 thumbs up U+1F44D
  lazy public var thumbsUpReactionView = MessageReactionButtonComponent(type: .custom)
  // ❤️ red heart U+2764
  lazy public var redHeartReactionView = MessageReactionButtonComponent(type: .custom)
  // 😂 face with tears of joy U+1F602
  lazy public var faceWithTearsOfJoyReactionView = MessageReactionButtonComponent(type: .custom)
  // 😲 astonished face U+1F632
  lazy public var astonishedFaceReactionView = MessageReactionButtonComponent(type: .custom)
  // 😢 crying face U+1F622
  lazy public var cryingFaceReactionView = MessageReactionButtonComponent(type: .custom)
  // 🔥 fire U+1F525
  lazy public var fireReactionView = MessageReactionButtonComponent(type: .custom)
  
  var reloadDelegate: ReloadCellDelegate?
  
  open override func setupSubviews() {
    super.setupSubviews()

    thumbsUpReactionView.reaction = "👍"
    redHeartReactionView.reaction = "❤️"
    faceWithTearsOfJoyReactionView.reaction = "😂"
    astonishedFaceReactionView.reaction = "😲"
    cryingFaceReactionView.reaction = "😢"
    fireReactionView.reaction = "🔥"
    
    stackView.alignment = .leading
    stackView.spacing = 5.0
    stackView.axis = .horizontal

    setupReactionViews([
      thumbsUpReactionView,
      redHeartReactionView,
      faceWithTearsOfJoyReactionView,
      astonishedFaceReactionView,
      cryingFaceReactionView,
      fireReactionView
    ])
  }

  open func setupReactionViews(
    _ reactionViews: [MessageReactionButtonComponent]
  ) {
    for reactionView in reactionViews {
      reactionView.messageReactionComponent.currentCountPublisher
        .sink { [weak reactionView, weak self] count in
          guard let reactionView = reactionView, let self = self else { return }

          switch (count == 0, self.stackView.arrangedSubviews.contains(reactionView)) {
          case (true, true):
            // Remove Reaction From View
            UIView.animate(withDuration: 0.5, animations: {
              reactionView.isHidden = true
              self.stackView.removeArrangedSubview(reactionView)
            })
          case (true, false):
            // Do Nothing
            break
          case (false, true):
            // Do Nothing
            break
          case (false, false):
            // Add Reaction to View
            UIView.animate(withDuration: 0.5, animations: {
              self.stackView.addArrangedSubview(reactionView)
              reactionView.isHidden = false
            })
          }
        }.store(in: &cancellables)
    }
  }
  
  open func configure<Message>(
    _ messageActionButtons: [MessageReactionButtonComponent],
    message: Message,
    currentUserId: String,
    onMessageActionTap: ((MessageReactionButtonComponent?, Message, (() -> Void)?) -> Void)?
  ) where Message : ManagedMessageViewModel {
    for messageActionButton in messageActionButtons {
      messageActionButton.cancellables.forEach { $0.cancel() }

      message.messageActionsPublisher
        .map { [weak messageActionButton] in
          // Filter out non-reactions and sourceType
          $0.filter { $0.sourceType == "reaction" && $0.value == messageActionButton?.reaction }
        }
        .sink { [weak messageActionButton] reactions in
          messageActionButton?.currentCount = reactions.count
          messageActionButton?.isSelected = reactions.contains(where: { $0.pubnubUserId == currentUserId })
        }
        .store(in: &messageActionButton.cancellables)
      
      messageActionButton
        .didTap({ [weak message] button in
          guard let message = message else { return }
          
          // Disable Button
          button?.isEnabled = false
          
          onMessageActionTap?(button, message) { [weak button] in
            DispatchQueue.main.async {
              button?.isEnabled = true
            }
          }
        })
        .store(in: &messageActionButton.cancellables)
    }
  }

  open func configure<Message>(
    _ message: Message,
    currentUserId: String,
    onMessageActionTap: ((MessageReactionButtonComponent?, Message, (() -> Void)?) -> Void)?
  ) where Message : ManagedMessageViewModel {
    
    // Thumbs Up
    configure(
      [
        thumbsUpReactionView,
        redHeartReactionView,
        faceWithTearsOfJoyReactionView,
        astonishedFaceReactionView,
        cryingFaceReactionView,
        fireReactionView
      ],
      message: message,
      currentUserId: currentUserId,
      onMessageActionTap: onMessageActionTap
    )
  }
}
