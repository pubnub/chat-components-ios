//
//  ContainerView.swift
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
import CoreData

import PubNub

public protocol ReloadDatasourceItemDelegate: AnyObject {
  func reloadAsyncContainer(_ identifier: NSManagedObjectID?)
}

extension ReloadDatasourceItemDelegate {
  public func reloadAsyncContainer(_ identifier: NSManagedObjectID?) { /* no-op */ }
}

public protocol ReloadCellDelegate: AnyObject {
  func reloadComponentCell()
}

extension ReloadCellDelegate {
  public func reloadComponentCell() { /* no-op */ }
}

// MARK: - UI Stack Container VIew

@dynamicMemberLookup
open class UIStackContainerView: UIView {

  public lazy var stackView = UIStackView()

  public var cancellables = Set<AnyCancellable>()
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupSubviews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    setupSubviews()
  }
  
  open func setupSubviews() {
    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false
    layoutMargins = .zero
    
    addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true

    stackView.bottomAnchor
      .constraint(equalTo: layoutMarginsGuide.bottomAnchor)
      .priority(.overrideRequire).isActive = true
    stackView.trailingAnchor
      .constraint(equalTo: layoutMarginsGuide.trailingAnchor)
      .priority(.overrideRequire).isActive = true
  }
  
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<UIStackView, T>) -> T {
    get { stackView[keyPath: keyPath] }
    set { stackView[keyPath: keyPath] = newValue }
  }

  func addArrangedSubview(_ view: UIView?) {
    stackView.addArrangedSubview(view)
  }
  
  func removeArrangedSubview(_ view: UIView?) {
    stackView.removeArrangedSubview(view)
  }
  
  func setCustomSpacing(_ spacing: CGFloat, after arrangedSubview: UIView?) {
    stackView.setCustomSpacing(spacing, after: arrangedSubview)
  }
  
  open func configure<Message: ManagedMessageViewModel>(
    _ message: Message,
    theme: MessageListCellComponentTheme
  ) {
    
  }
  
  open func configure<Channel: ManagedChannelViewModel>(
    _ channel: Channel,
    theme: BasicComponentTheme
  ) {
    
  }
  
  open func configure<Member: ManagedMemberViewModel>(
    _ member: Member,
    theme: BasicComponentTheme
  ) {
    
  }
  
  open func configure<User: ManagedUserViewModel>(
    _ user: User,
    theme: BasicComponentTheme
  ) {
    
  }
}

extension UIStackView {
  func addArrangedSubview(_ view: UIView?) {
    guard let view = view else { return }
    addArrangedSubview(view)
  }

  func removeArrangedSubview(_ view: UIView?) {
    guard let view = view else { return }
    removeArrangedSubview(view)
  }
  
  func setCustomSpacing(_ spacing: CGFloat, after arrangedSubview: UIView?) {
    guard let arrangedSubview = arrangedSubview else { return }
    setCustomSpacing(spacing, after: arrangedSubview)
  }
}

// MARK: - Bar Button Item

public class BarButtonItemComponent: UIBarButtonItem {
  
  let containerView: UIStackView = UIStackView()
  var cancellables = Set<AnyCancellable>()
  
  public let button = UIButton(type: .system)
  
  public required init(action: ((UIBarButtonItem?) -> Void)?) {
    super.init()
    
    self.customView = button

    button
      .publisher(for: .touchUpInside).sink { [weak self] controlPublisher in
        action?(self)
      }
      .store(in: &cancellables)
    
    setupSubviews()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open func setupSubviews() {
    
  }
}
