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

public class MessageReactionListComponent: UIView {//UIStackContainerView {

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

  var currentCount: Int = 0
  
  public override var intrinsicContentSize: CGSize {
    return super.intrinsicContentSize
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupSubviews()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    setupSubviews()
  }
  
  lazy public var stackViewContainer = UIStackContainerView()

  var allReactions: [MessageReactionButtonComponent] {
    [
      thumbsUpReactionView,
      redHeartReactionView,
      faceWithTearsOfJoyReactionView,
      astonishedFaceReactionView,
      cryingFaceReactionView,
      fireReactionView
    ]
  }
  
  open func setupSubviews() {
    translatesAutoresizingMaskIntoConstraints = false

    thumbsUpReactionView.reaction = "👍"
    redHeartReactionView.reaction = "❤️"
    faceWithTearsOfJoyReactionView.reaction = "😂"
    astonishedFaceReactionView.reaction = "😲"
    cryingFaceReactionView.reaction = "😢"
    fireReactionView.reaction = "🔥"
    
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
    onMessageActionTap: ((MessageReactionButtonComponent?, Message, (() -> Void)?) -> Void)?
  ) where Message : ManagedMessageViewModel {
    
    var newCount = 0
    
    for messageActionButton in messageActionButtons {
      messageActionButton.externalCancellables.forEach { $0.cancel() }
      
      // new way
      let reactions = message.messageActions
        .filter { $0.sourceType == "reaction" && $0.value == messageActionButton.reaction }
      if reactions.count > 0 {
        newCount += reactions.count
        
        messageActionButton.currentCount = reactions.count
        messageActionButton.isSelected = reactions.contains(where: { $0.pubnubUserId == currentUserId })

        if messageActionButton.superview == nil {
          stackViewContainer.stackView.addArrangedSubview(messageActionButton)
          setNeedsLayout()
        }
        
        messageActionButton.didTap({ [weak message] button in
          guard let message = message else { return }
          
          // Disable Button
          button?.isEnabled = false
          
          onMessageActionTap?(button, message) { [weak button] in
            DispatchQueue.main.async {
              button?.isEnabled = true
            }
          }
        })
        .store(in: &messageActionButton.externalCancellables)
      } else {
        if messageActionButton.superview != nil {
          messageActionButton.removeFromSuperview()
          stackViewContainer.stackView.removeArrangedSubview(messageActionButton)
          setNeedsLayout()
        }
      }
    }
    currentCount = newCount
    isHidden = newCount == 0 ? true : false
    
    stackViewContainer.layoutIfNeeded()
    layoutIfNeeded()
  }

  open func configure<Message>(
    _ message: Message,
    currentUserId: String,
    onMessageActionTap: ((MessageReactionButtonComponent?, Message, (() -> Void)?) -> Void)?
  ) where Message : ManagedMessageViewModel {
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
