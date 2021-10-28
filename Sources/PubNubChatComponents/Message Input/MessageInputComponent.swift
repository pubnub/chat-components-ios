//
//  MessageInputComponent.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2021 PubNub Inc.
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

import PubNubChat
import InputBarAccessoryView
import ChatLayout

open class MessageInputComponent: UIView {
  
  public var typingIndicatorService: TypingIndicatorService = .shared

  public var sizeChangeSubject = PassthroughSubject<CGSize, Never>()
  public var sendMessageSubject = PassthroughSubject<(MessageInputComponent, String), Never>()
  public var typingDidChangeSubject = CurrentValueSubject<Bool, Never>(false)

  public var inputTextView: UITextView?
  public var sendButton: UIButton?
  
  public var placeholder: String?
  public var placeholderTextColor: UIColor?
  public var placeholderTextFont: UIFont?
  
  public weak var parentComponentView: UIView!
  public weak var attachedSrollView: UIScrollView!
  public weak var componentBottomConstraint: NSLayoutConstraint?
  
  public var cancellables = Set<AnyCancellable>()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupComponent()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupComponent()
  }
  
  private var canBecomeFirstResponderStorage: Bool = true
  open override var canBecomeFirstResponder: Bool {
    get { canBecomeFirstResponderStorage }
    set(newValue) { canBecomeFirstResponderStorage = newValue }
  }
  
  open func setupComponent() {
    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false
    layoutMargins = .zero
    
    NotificationCenter.default
      .publisher(for: UIResponder.keyboardWillChangeFrameNotification, object: nil)
      .map { KeyboardNotification($0) }
      .sink { [weak self] notification in
        self?.keyboardWillChangeFrame(notification)
      }
      .store(in: &cancellables)
  }
  
  open func clearMessageInput() {
    inputTextView?.resignFirstResponder()
    inputTextView?.text = ""
  }
  
  open func bind(_ parent: UIView, scrollView: UIScrollView, bottomInset: NSLayoutConstraint?) {
    self.parentComponentView = parent
    self.attachedSrollView = scrollView
    self.componentBottomConstraint = bottomInset
  }

  private func keyboardWillChangeFrame(_ notification: KeyboardNotification?) {
    guard let notification = notification else { return }
    
    let currentFrame = parentComponentView.convert(notification.frameEnd, from: nil)
    let frameAtStart = parentComponentView.convert(notification.frameBegin, from: nil)

    componentBottomConstraint?.constant = -(parentComponentView.bounds.height - currentFrame.minY)

    var keyboardTop = currentFrame.minY
    if keyboardTop == parentComponentView.bounds.height { keyboardTop -= parentComponentView.safeAreaInsets.bottom }
    
    var oldKeyboardTop = frameAtStart.minY
    if oldKeyboardTop == parentComponentView.bounds.height { oldKeyboardTop -= parentComponentView.safeAreaInsets.bottom }
    
    let keyboardDelta = oldKeyboardTop - keyboardTop

    let contentDelta = max(
      attachedSrollView.frame.height - attachedSrollView.contentSize.height + attachedSrollView.contentOffset.y - 8,
      0
    )
    
    let newContentOffset = CGPoint(
      x: 0,
      y: max(
        attachedSrollView.contentOffset.y + keyboardDelta - contentDelta,
        -attachedSrollView.contentInset.top
      )
    )

    // changing contentOffset will cancel any scrolling in collectionView, bad UX
    let needUpdateContentOffset = !attachedSrollView.isDecelerating && !attachedSrollView.isDragging

    UIView.animate(
      withDuration: notification.animationDuration,
      delay: 0.0,
      options: notification.animationCurve,
      animations: { [weak self] in
        self?.parentComponentView.layoutIfNeeded()
        if needUpdateContentOffset {
          self?.attachedSrollView.contentOffset = newContentOffset
        }
      }
    )
  }
}

// MARK: - InputBarAccessoryView impl.

open class MessageInputBarComponent: MessageInputComponent, InputBarAccessoryViewDelegate {

  private lazy var inputBarAccessoryView = InputBarAccessoryView()
  
  public override var backgroundColor: UIColor? {
    get {
      inputBarAccessoryView.backgroundView.backgroundColor
    }
    set {
      inputBarAccessoryView.backgroundView.backgroundColor = newValue
    }
  }

  public override var inputTextView: UITextView? {
    get {
      return inputBarAccessoryView.inputTextView
    }
    set(newValue) {
      guard let newInputTextView = newValue as? InputTextView else { return }

      inputBarAccessoryView.inputTextView = newInputTextView
    }
  }
  
  public override var sendButton: UIButton? {
    get {
      return inputBarAccessoryView.sendButton
    }
    set(newValue) {
      guard let _ = newValue as? InputBarButtonItem else { return }
    }
  }
  
  public override var placeholder: String? {
    get {
      return inputBarAccessoryView.inputTextView.placeholder
    }
    set(newValue) {
      inputBarAccessoryView.inputTextView.placeholder = newValue
    }
  }
  public override var placeholderTextColor: UIColor? {
    get {
      return inputBarAccessoryView.inputTextView.placeholderTextColor
    }
    set(newValue) {
      inputBarAccessoryView.inputTextView.placeholderTextColor = newValue
    }
  }
  public override var placeholderTextFont: UIFont? {
    get {
      return inputBarAccessoryView.inputTextView.placeholderLabel.font
    }
    set(newValue) {
      inputBarAccessoryView.inputTextView.placeholderLabel.font = newValue
    }
  }

  open override func setupComponent() {
    super.setupComponent()
    
    addSubview(inputBarAccessoryView)
    inputBarAccessoryView.translatesAutoresizingMaskIntoConstraints = false
    inputBarAccessoryView.leadingAnchor
      .constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    inputBarAccessoryView.trailingAnchor
      .constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    inputBarAccessoryView.topAnchor
      .constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    inputBarAccessoryView.bottomAnchor
      .constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    
    inputBarAccessoryView.delegate = self
    inputBarAccessoryView.shouldAnimateTextDidChangeLayout = true
  }
  
  open override func clearMessageInput() {
    super.clearMessageInput()
    // Clear Plugins
    inputBarAccessoryView.invalidatePlugins()
  }

// MARK: - InputBarAccessoryViewDelegate

  public func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
    sizeChangeSubject.send(size)
  }
  
  public func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
    guard !text.isEmpty else { return }

    sendMessageSubject.send((self, text))
  }
  
  public func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
    typingDidChangeSubject.send(!text.isEmpty)
  }
}

// MARK: - KeyboardNotification

public struct KeyboardNotification {
  public let frameBegin: CGRect
  public let frameEnd: CGRect
  public let animationCurve: UIView.AnimationOptions
  public let animationDuration: TimeInterval
  public let isLocal: Bool
  
  public init?(_ notification: Notification) {
    guard let frameBegin = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
          let frameEnd = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
          let rawCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let isLocal =  notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool else {
            return nil
          }
    
    self.frameBegin = frameBegin
    self.frameEnd = frameEnd
    self.animationCurve = UIView.AnimationOptions(rawValue: rawCurve)
    self.animationDuration = animationDuration
    self.isLocal = isLocal
  }
}
