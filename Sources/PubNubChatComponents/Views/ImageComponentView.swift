//
//  AvatarComponentView.swift
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

import Kingfisher
import ChatLayout

public protocol ImageComponentView: UIImageView {
  @discardableResult
  func configure(
    _ contentPublisher: AnyPublisher<URL?, Never>,
    placeholder: AnyPublisher<UIImage?, Never>,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self

  @discardableResult
  func configure(
    _ contentPublisher: AnyPublisher<URL?, Never>,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self
  
  @discardableResult
  func configure(
    _ contentPublisher: AnyPublisher<UIImage?, Never>,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self
}

// MARK: Default Content

extension ImageComponentView {
  public func configure(
    _ contentPublisher: AnyPublisher<URL?, Never>,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self {
    return configure(
      contentPublisher,
      placeholder: CurrentValueSubject<UIImage?, Never>(nil).eraseToAnyPublisher(),
      cancelIn: &cancelIn
    )
  }
  
  func configure(
    _ contentPublisher: AnyPublisher<URL?, Never>,
    placeholder: AnyPublisher<UIImage?, Never>?,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self {
    return configure(
      contentPublisher,
      placeholder: placeholder ?? CurrentValueSubject<UIImage?, Never>(nil).eraseToAnyPublisher(),
      cancelIn: &cancelIn
    )
  }
  
  public func configure(
    _ contentPublisher: AnyPublisher<UIImage?, Never>,
    cancelIn store: inout Set<AnyCancellable>
  ) -> Self {
    contentPublisher
      .weakAssign(to: \.image, on: self)
      .store(in: &store)
    
    return self
  }
  
  public func configure(
    _ contentPublisher: AnyPublisher<URL?, Never>,
    placeholder: AnyPublisher<UIImage?, Never>,
    cancelIn: inout Set<AnyCancellable>
  ) -> Self {
    
    let publisher = contentPublisher.combineLatest(placeholder).eraseToAnyPublisher()
    
    publisher
      .handleEvents(receiveCancel: { [weak self] in
        self?.kf.cancelDownloadTask()
        self?.image = nil
      })
      .sink(receiveValue: { [weak self] url, placeholder in
        self?.kf.setImage(
          with: url, placeholder: placeholder
        )
      })
      .store(in: &cancelIn)
    
    return self
  }
}

extension UIImageView: ImageComponentView {}

open class CircleImageComponentView: UIImageView {

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupSubviews()
  }
  
  internal func setupSubviews() {
    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false
    layoutMargins = .zero

    contentMode = .scaleAspectFit
    layer.masksToBounds = true
    clipsToBounds = true
    
    setCorner()
  }
  
  // MARK: - Overridden Properties
  open override var frame: CGRect {
    didSet {
      setCorner()
    }
  }

  open override var bounds: CGRect {
    didSet {
      setCorner()
    }
  }

  open func setCorner() {
    layer.cornerRadius = min(frame.width, frame.height)/2
  }
}

open class PubNubInlineAvatarComponentView: UIView {
  
  public lazy var imageView = CircleImageComponentView(frame: bounds)
  
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
    
    addSubview(imageView)
    
    imageView.translatesAutoresizingMaskIntoConstraints = false
    
    imageView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    imageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    
    imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
  }
}
