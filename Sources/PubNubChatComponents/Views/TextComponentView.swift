//
//  TextComponentView.swift
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

import ChatLayout
import Kingfisher

import PubNubChat

final public class TextComponentView: UIView {

  private var viewPortWidth: CGFloat = 300
  private var maxWidthPercentage: CGFloat = 0.65

  public lazy var textView = MessageContentTextView()
  private var textViewWidthConstraint: NSLayoutConstraint?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupSubviews()
  }

  private func setupSubviews() {
    layoutMargins = .zero
    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false
    
    textView.translatesAutoresizingMaskIntoConstraints = false

    textView.textContainer.lineFragmentPadding = 0
    textView.layoutManager.allowsNonContiguousLayout = true

    addSubview(textView)
    textView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    textView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    textView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    textView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    textViewWidthConstraint = textView.widthAnchor.constraint(lessThanOrEqualToConstant: viewPortWidth)
    textViewWidthConstraint?.isActive = true
  }
  
  private func setupSize() {
    UIView.performWithoutAnimation {
      self.textViewWidthConstraint?.constant = viewPortWidth * maxWidthPercentage
      setNeedsLayout()
    }
  }
}

public protocol TextViewComponentView: UITextView {
  // Content
  @discardableResult
  func configure(
  _ textPublisher: AnyPublisher<String?, Never>,
cancelIn: inout Set<AnyCancellable>
  ) -> Self
  
  @discardableResult
  func configure(
    _ textPublisher: AnyPublisher<String, Never>,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self
  
  @discardableResult
  func configure(
    _ datePublisher: AnyPublisher<Date, Never>,
    formatter: DateFormatter,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self
  
  // Theme
  
  func theming(
    _ themePublisher: TextViewComponentTheme,
    cancelIn: inout Set<AnyCancellable>
  )
}

extension TextViewComponentView {
  @discardableResult
  public func configure(
    _ datePublisher: AnyPublisher<Date, Never>,
    formatter: DateFormatter,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self {
    return configure(
      datePublisher.map({ formatter.string(from: $0) }).eraseToAnyPublisher(),
      cancelIn: &cancelIn
    )
  }
  @discardableResult
  public func configure(
    _ textPublisher: AnyPublisher<String, Never>,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self {
    return configure(
      textPublisher.map({ Optional($0) }).eraseToAnyPublisher(),
      cancelIn: &cancelIn
    )
  }
  @discardableResult
  public func configure(
  _ textPublisher: AnyPublisher<String?, Never>,
cancelIn: inout Set<AnyCancellable>
  ) -> Self {
    textPublisher.weakAssign(to: \.text, on: self).store(in: &cancelIn)
    return self
  }
}

/// UITextView with hacks to avoid selection
public final class MessageContentTextView: UITextView, TextViewComponentView {
  public override var isFocused: Bool {
    return false
  }
  
  public override var canBecomeFirstResponder: Bool {
    return false
  }
  
  public override var canBecomeFocused: Bool {
    return false
  }
  
  public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return false
  }
}
