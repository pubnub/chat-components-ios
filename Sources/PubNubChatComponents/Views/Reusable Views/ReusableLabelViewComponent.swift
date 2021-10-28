//
//  HeaderLabelView.swift
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

open class ReusableComponentView: UICollectionReusableView {
  
  public var cancellables = Set<AnyCancellable>()
  public var contentCancellables = Set<AnyCancellable>()
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupSubviews()
  }
  
  open func setupSubviews() {
    insetsLayoutMarginsFromSafeArea = false
    layoutMargins = .zero
  }
  
  // MARK: CollectionView Inversion

  public static func registerHeader(_ collectionView: UICollectionView) {
    collectionView.register(header: Self.self)
  }

  public static func registerFooter(_ collectionView: UICollectionView) {
    collectionView.register(footer: Self.self)
  }
  
  public static func dequeueHeader(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath
  ) throws -> ReusableComponentView {
    return try collectionView.dequeueHeader(Self.self, for: indexPath)
  }
  
  public static func dequeueFooter(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath
  ) throws -> ReusableComponentView {
    return try collectionView.dequeueFooter(Self.self, for: indexPath)
  }

  public static func dequeueCustom(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    of elementKind: String
  ) throws -> ReusableComponentView {
    return try collectionView.dequeueCustom(Self.self, ofKind: elementKind, for: indexPath)
  }
  
  // MARK: Content Configuration
  
  open func configure<Content: BasicComponentViewModel>(
    _ content: Content,
    theme: BasicComponentTheme
  ) {
    
  }
}

public class ReusableLabelViewComponent: ReusableComponentView {
  private lazy var titleLabel: LabelComponentView = PubNubLabelComponentView(frame: bounds)

  open override func setupSubviews() {
    addSubview(titleLabel)
    
    titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
  }
  
  open override func configure<Content: BasicComponentViewModel>(
    _ content: Content,
    theme: BasicComponentTheme
  ) {
    titleLabel
      .configure(content.$primaryLabel.eraseToAnyPublisher(), cancelIn: &contentCancellables)
      .theming(theme.primaryLabel, cancelIn: &contentCancellables)
  }
}
