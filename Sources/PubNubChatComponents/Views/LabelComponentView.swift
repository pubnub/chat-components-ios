//
//  DateLabelView.swift
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

public protocol LabelComponentView: UILabel {
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
}

extension LabelComponentView {
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

extension UILabel: LabelComponentView {}

open class PubNubLabelComponentView: UIView {
  
  public lazy var labelView: LabelComponentView = UILabel(frame: bounds)

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupSubviews()
  }
  
  open func setupSubviews() {
    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false
    layoutMargins = .zero

    addSubview(labelView)

    labelView.translatesAutoresizingMaskIntoConstraints = false
    labelView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    labelView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    labelView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    labelView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
  }
}

