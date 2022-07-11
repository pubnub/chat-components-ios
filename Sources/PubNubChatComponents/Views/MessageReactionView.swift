//
//  MessageReactionView.swift
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

public class MessageReactionComponent: UIStackContainerView {
  
  public var reactionCountPublisher = CurrentValueSubject<Int, Never>(0)
  public var currentCount: Int {
    get {
      reactionCountPublisher.value
    }
    set {
      reactionCountPublisher.send(newValue)
    }
  }
  
  public var reactionValuePublisher = CurrentValueSubject<String, Never>("")
  public var reaction: String {
    get {
      reactionValuePublisher.value
    }
    set {
      reactionValuePublisher.send(newValue)
    }
  }
  
  public var isHighlightedPublisher = CurrentValueSubject<Bool, Never>(false)
  public var isHighlighted: Bool {
    get {
      isHighlightedPublisher.value
    }
    set {
      isHighlightedPublisher.send(newValue)
    }
  }
  
  lazy public var emojiLabel = PubNubLabelComponentView(frame: bounds)
  lazy public var countLabel = PubNubLabelComponentView(frame: bounds)
  
  open override func setupSubviews() {
    super.setupSubviews()

    stackView.alignment = .center
    stackView.spacing = 5.0
    stackView.axis = .horizontal
    
    emojiLabel.font = AppearanceTemplate.Font.footnote
    countLabel.font = AppearanceTemplate.Font.footnote

    stackView.addArrangedSubview(emojiLabel)
    stackView.addArrangedSubview(countLabel)
    
    emojiLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
    stackView.heightAnchor.constraint(equalTo: emojiLabel.heightAnchor).isActive = true
    
    self.emojiLabel = emojiLabel
    self.countLabel = countLabel
    
    isHighlightedPublisher
      .sink { [weak self] status in
        if status {
          self?.backgroundColor = AppearanceTemplate.Color.messageActionActive
        } else {
          self?.backgroundColor = .clear
        }
      }
      .store(in: &cancellables)
    
    self.layoutMargins = UIEdgeInsets(top: 1, left: 3, bottom: 1, right: 7);
    self.layer.cornerRadius = 10
    self.layer.borderWidth = 1
    self.layer.borderColor = UIColor.black.cgColor
    
    // Enable/Disable the view based on current count
    reactionCountPublisher
      .sink { [weak self] count in
        if count > 0 {
          self?.isHidden = false
        } else {
          self?.isHidden = true
        }
      }
      .store(in: &cancellables)
    
    self.emojiLabel
      .configure(
        reactionValuePublisher.eraseToAnyPublisher(),
        cancelIn: &cancellables
      )
    
    // Update the current count as the count changes
    self.countLabel
      .configure(
        reactionCountPublisher.map({ $0.description }).eraseToAnyPublisher(),
        cancelIn: &cancellables
      )
  }
}

public class MessageReactionButtonComponent: UIButton {
  
  lazy var messageReactionComponent = MessageReactionComponent(frame: bounds)
  
  var cancellables = Set<AnyCancellable>()
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupSubviews()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    setupSubviews()
  }
  
  open func setupSubviews() {
    messageReactionComponent.isUserInteractionEnabled = false
    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false
    layoutMargins = .zero

    self.addSubview(messageReactionComponent)
    
    leadingAnchor.constraint(equalTo: messageReactionComponent.leadingAnchor).isActive = true
    trailingAnchor.constraint(equalTo: messageReactionComponent.trailingAnchor).isActive = true
    topAnchor.constraint(equalTo: messageReactionComponent.topAnchor).isActive = true
    heightAnchor.constraint(equalTo: messageReactionComponent.heightAnchor).isActive = true

    self.messageReactionComponent = messageReactionComponent
  }

  public func didTap(_ action: ((MessageReactionButtonComponent?) -> Void)?) -> AnyCancellable {
    return publisher(for: .touchUpInside)
      .sink { [weak self] controlPublisher in
        action?(self)
        self?.isSelected.toggle()
      }
  }

  // MARK: MessageReactionComponent Outlets
  
  public var currentCount: Int {
    get {
      messageReactionComponent.currentCount
    }
    set {
      messageReactionComponent.currentCount = newValue
    }
  }

  public var reaction: String {
    get {
      messageReactionComponent.reaction
    }
    set {
      messageReactionComponent.reaction = newValue
    }
  }

  public override var isSelected: Bool {
    get {
      messageReactionComponent.isHighlighted
    }
    set {
      messageReactionComponent.isHighlighted = newValue
    }
  }

  public override var isHidden: Bool {
    get {
      messageReactionComponent.isHidden
    }
    set {
      messageReactionComponent.isHidden = newValue
    }
  }
}
