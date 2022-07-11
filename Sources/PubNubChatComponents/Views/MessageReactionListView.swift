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
    
    stackView.addArrangedSubview(thumbsUpReactionView)
    stackView.addArrangedSubview(redHeartReactionView)
    stackView.addArrangedSubview(faceWithTearsOfJoyReactionView)
    stackView.addArrangedSubview(astonishedFaceReactionView)
    stackView.addArrangedSubview(cryingFaceReactionView)
    stackView.addArrangedSubview(fireReactionView)
    
    self.thumbsUpReactionView = thumbsUpReactionView
    self.redHeartReactionView = redHeartReactionView
    self.faceWithTearsOfJoyReactionView = faceWithTearsOfJoyReactionView
    self.astonishedFaceReactionView = astonishedFaceReactionView
    self.cryingFaceReactionView = cryingFaceReactionView
    self.fireReactionView = fireReactionView
  }

  open func configure<Message>(
    _ message: Message,
    currentUserId: String,
    onMessageActionTap: ((MessageReactionButtonComponent?, Message) -> Void)?
  ) where Message : ManagedMessageViewModel {

    // Thumbs Up
    message.messageActionsPublisher
      .map { [weak self] in
        // Filter out non-reactions and sourceType
        $0.filter {
          $0.sourceType == "reaction" && $0.value == self?.thumbsUpReactionView.reaction
        }
      }
      .sink { [weak self] reactions in
        self?.thumbsUpReactionView.currentCount = reactions.count
        self?.thumbsUpReactionView.isSelected = reactions.contains(where: { $0.pubnubUserId == currentUserId })
      }
      .store(in: &cancellables)
    thumbsUpReactionView
      .didTap({ button in
        onMessageActionTap?(button, message)
      })
      .store(in: &cancellables)
  
    message.messageActionsPublisher
      .map { [weak self] in
        // Filter out non-reactions and sourceType
        $0.filter { $0.sourceType == "reaction" && $0.value == self?.redHeartReactionView.reaction }
      }
      .sink { [weak self] reactions in
        self?.redHeartReactionView.currentCount = reactions.count
        self?.redHeartReactionView.isSelected = true
      }
      .store(in: &cancellables)
    
    message.messageActionsPublisher
      .map { [weak self] in
        // Filter out non-reactions and sourceType
        $0.filter { $0.sourceType == "reaction" && $0.value == self?.faceWithTearsOfJoyReactionView.reaction }
      }
      .count()
      .sink { [weak self] thumbsUpCount in
        self?
          .faceWithTearsOfJoyReactionView
          .currentCount = thumbsUpCount
      }
      .store(in: &cancellables)
    
    message.messageActionsPublisher
      .map { [weak self] in
        // Filter out non-reactions and sourceType
        $0.filter { $0.sourceType == "reaction" && $0.value == self?.astonishedFaceReactionView.reaction }
      }
      .count()
      .sink { [weak self] thumbsUpCount in
        self?
          .astonishedFaceReactionView
          .currentCount = thumbsUpCount
      }
      .store(in: &cancellables)
    
    message.messageActionsPublisher
      .map { [weak self] in
        // Filter out non-reactions and sourceType
        $0.filter { $0.sourceType == "reaction" && $0.value == self?.cryingFaceReactionView.reaction }
      }
      .count()
      .sink { [weak self] thumbsUpCount in
        self?
          .cryingFaceReactionView
          .currentCount = thumbsUpCount
      }
      .store(in: &cancellables)
    
    message.messageActionsPublisher
      .map { [weak self] in
        // Filter out non-reactions and sourceType
        $0.filter { $0.sourceType == "reaction" && $0.value == self?.fireReactionView.reaction }
      }
      .count()
      .sink { [weak self] thumbsUpCount in
        self?
          .fireReactionView
          .currentCount = thumbsUpCount
      }
      .store(in: &cancellables)
  }
}
