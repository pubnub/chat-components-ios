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

import PubNub

public class MessageReactionComponent: UIStackContainerView {
  
  var currentCountPublisher = CurrentValueSubject<Int, Never>(0)
  public var currentCount: Int {
    get {
      currentCountPublisher.value
    }
    set {
      if newValue >= 0 {
        currentCountPublisher.send(newValue)
      } else {
        currentCountPublisher.send(0)
      }
    }
  }
  @Published public var reaction = ""
  @Published public var isHighlighted = false

  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupSubviews()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    setupSubviews()
  }
  
  lazy public var emojiLabel = PubNubLabelComponentView(frame: bounds)
  lazy public var countLabel = PubNubLabelComponentView(frame: bounds)
  
  open override func setupSubviews() {

    stackView.alignment = .center
    stackView.axis = .horizontal
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.directionalLayoutMargins = .init(top: 2, leading: 3, bottom: 2, trailing: 7)

    layer.cornerRadius = 10
    layer.borderWidth = 1
    layer.borderColor = UIColor.black.cgColor
  
    emojiLabel.labelView.font = AppearanceTemplate.Font.footnote
    emojiLabel.labelView.adjustsFontForContentSizeCategory = false
    emojiLabel.labelView.translatesAutoresizingMaskIntoConstraints = false

    countLabel.labelView.font = AppearanceTemplate.Font.footnote
    countLabel.labelView.adjustsFontForContentSizeCategory = false
    countLabel.labelView.translatesAutoresizingMaskIntoConstraints = false

    stackView.addArrangedSubview(emojiLabel)
    stackView.setCustomSpacing(2.0, after: emojiLabel)
    stackView.addArrangedSubview(countLabel)
    
    super.setupSubviews()

    $isHighlighted
      .sink { [weak self] status in
        if status {
          self?.backgroundColor = AppearanceTemplate.Color.messageActionActive
        } else {
          self?.backgroundColor = .clear
        }
      }
      .store(in: &cancellables)
    
    // Enable/Disable the view based on current count
    currentCountPublisher
      .sink { [weak self] count in
        if count > 0 {
          self?.isHidden = false
        } else {
          self?.isHidden = true
        }
      }
      .store(in: &cancellables)
    
    emojiLabel.labelView
      .configure(
        $reaction.eraseToAnyPublisher(),
        cancelIn: &cancellables
      )
    
    countLabel.labelView
      .configure(
        currentCountPublisher.map({ $0.description }).eraseToAnyPublisher(),
        cancelIn: &cancellables
      )
  }
}

public class MessageReactionButtonComponent: UIButton {
  
  lazy var messageReactionComponent = MessageReactionComponent(frame: bounds)

  var cancellables = Set<AnyCancellable>()
  
  var externalCancellables = Set<AnyCancellable>()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupSubviews()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    setupSubviews()
  }

  open override var intrinsicContentSize: CGSize {
    return CGSize(width: bounds.width, height: 20)
  }
  
  open func setupSubviews() {

    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false
    layoutMargins = .zero
    
    messageReactionComponent.isUserInteractionEnabled = false
    
    addSubview(messageReactionComponent)
        
    messageReactionComponent.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    messageReactionComponent.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    messageReactionComponent.topAnchor.constraint(equalTo: topAnchor).isActive = true
    messageReactionComponent.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    
    messageReactionComponent.publisher(for: \.isHidden).sink { [weak self] isHidden in
      self?.isHidden = isHidden
    }.store(in: &cancellables)
  }

  public func didTap(_ action: ((MessageReactionButtonComponent?) -> Void)?) -> AnyCancellable {
    return publisher(for: .touchUpInside)
      .sink { [weak self] controlPublisher in
        if self?.isEnabled == true {
          action?(self)
          self?.isSelected.toggle()
        }
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
}
