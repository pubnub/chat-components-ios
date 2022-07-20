//
//  UserInlineDetailComponentView.swift
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

open class UserInlineDetailComponentView: UIStackContainerView {
  
  open var primaryImageView: PubNubInlineAvatarComponentView?
  open var primaryLabel: PubNubLabelComponentView?
  
  open override func setupSubviews() {
    super.setupSubviews()
    
    let avatarView = PubNubInlineAvatarComponentView(frame: bounds)
    let nameLabel = PubNubLabelComponentView(frame: bounds)
    
//    stackView.distribution = .fillEqually
    stackView.alignment = .center
    stackView.spacing = 5.0
    stackView.addArrangedSubview(avatarView)
    stackView.addArrangedSubview(nameLabel)
    
    avatarView.heightAnchor.constraint(equalTo: stackView.heightAnchor).isActive = true
    avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor).isActive = true
    
    primaryImageView = avatarView
    primaryLabel = nameLabel
    
    primaryImageView?.setNeedsLayout()
  }
  
  open override func configure<User: ManagedUserViewModel>(
    _ user: User,
    theme: BasicComponentTheme
  ) {
    primaryImageView?.imageView
      .configure(
        user.userAvatarUrlPublisher,
        placeholder: theme.imageView.$localImage.eraseToAnyPublisher(),
        cancelIn: &cancellables
      )
      .theming(theme.imageView, cancelIn: &cancellables)
    
    primaryLabel?.labelView
      .configure(user.userNamePublisher.map({ $0 }).eraseToAnyPublisher(), cancelIn: &cancellables)
      .theming(theme.primaryLabel, cancelIn: &cancellables)
  }
}
