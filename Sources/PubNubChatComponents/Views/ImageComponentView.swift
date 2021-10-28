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
  // Content
//  var imageView: UIImageView { get }
  func setCorner(radius: CGFloat?)
  
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

open class PubNubAvatarComponentView: UIImageView, ImageComponentView {

  private var radius: CGFloat?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    prepareView()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    prepareView()
  }
  
  internal func prepareView() {
    contentMode = .scaleAspectFit
    layer.masksToBounds = true
    clipsToBounds = true
    
    setCorner(radius: nil)
  }
  
  // MARK: - Overridden Properties
  open override var frame: CGRect {
    didSet {
      setCorner(radius: self.radius)
    }
  }
  
  open override var bounds: CGRect {
    didSet {
      setCorner(radius: self.radius)
    }
  }

  open func setCorner(radius: CGFloat?) {
    guard let radius = radius else {
      //if corner radius not set default to Circle
      let cornerRadius = min(frame.width, frame.height)
      layer.cornerRadius = cornerRadius/2
      return
    }
    self.radius = radius
    layer.cornerRadius = radius
  }
}

//open class AvatarView: UIImageView {
//  
//  // MARK: - Properties
//  
//  private var radius: CGFloat?
//  
//  // MARK: - Overridden Properties
//  open override var frame: CGRect {
//    didSet {
//      setCorner(radius: self.radius)
//    }
//  }
//  
//  open override var bounds: CGRect {
//    didSet {
//      setCorner(radius: self.radius)
//    }
//  }
//  
//  // MARK: - Initializers
//  public override init(frame: CGRect) {
//    super.init(frame: frame)
//    prepareView()
//  }
//  
//  required public init?(coder aDecoder: NSCoder) {
//    super.init(coder: aDecoder)
//    prepareView()
//  }
//  
//  convenience public init() {
//    self.init(frame: .zero)
//    prepareView()
//  }
//
//  
//  // MARK: - Internal methods
//  internal func prepareView() {
//    contentMode = .scaleAspectFill
//    layer.masksToBounds = true
//    clipsToBounds = true
//    setCorner(radius: nil)
//  }
//  
//  // MARK: - Open setters
//  
//  open func set(avatar: UIImage?) {
//    if let image = image {
//      self.image = image
//    }
//  }
//  
//  open func setCorner(radius: CGFloat?) {
//    guard let radius = radius else {
//      //if corner radius not set default to Circle
//      let cornerRadius = min(frame.width, frame.height)
//      layer.cornerRadius = cornerRadius/2
//      return
//    }
//    self.radius = radius
//    layer.cornerRadius = radius
//  }
//  
//}
