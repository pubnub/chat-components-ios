//
//  ChannelMemberComponentCell.swift
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


open class ChannelMemberComponentCell: CollectionViewCellComponent {
 
  open var primaryImageView: PubNubInlineAvatarComponentView?
  open var primaryLabel: PubNubLabelComponentView?
  open var secondaryLabel: PubNubLabelComponentView?
  
  // TODO: This might need to change to a wrapped stack component
  public let contentContainer = UIStackView()
  
  open override func setupSubviews() {
    super.setupSubviews()
    
    let avatarView = PubNubInlineAvatarComponentView(frame: bounds)
    self.primaryLabel = PubNubLabelComponentView(frame: bounds)
    self.secondaryLabel = PubNubLabelComponentView(frame: bounds)

    // Arrange Top Container
    contentContainer.axis = .vertical
    contentContainer.alignment = .leading
    contentContainer.addArrangedSubview(primaryLabel)
    contentContainer.addArrangedSubview(secondaryLabel?.priorityFill(axis: .vertical))

    cellContainer.alignment = .center
    cellContainer.spacing = 5.0
    cellContainer.addArrangedSubview(avatarView)
    cellContainer.addArrangedSubview(contentContainer)
    
    avatarView.heightAnchor.constraint(equalTo: cellContainer.heightAnchor, multiplier: 0.75).isActive = true
    avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor).isActive = true
  
    primaryImageView = avatarView
  }
  
  // MARK: - Configure Data
  
  open override func configure<Channel: ManagedChannelViewModel>(
    _ channel: Channel,
    theme: ChannelListCellComponentTheme
  ) {
    primaryImageView?.imageView
      .configure(
        channel.channelAvatarUrlPublisher,
        placeholder: theme.itemTheme.imageView.$localImage.eraseToAnyPublisher(),
        cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.imageView, cancelIn: &contentCancellables)
    
    primaryLabel?.labelView
      .configure(
        channel.channelNamePublisher.map({ $0 }).eraseToAnyPublisher(), cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.primaryLabel, cancelIn: &contentCancellables)
    
    secondaryLabel?.labelView
      .configure(
        channel.channelDetailsPublisher, cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.secondaryLabel, cancelIn: &contentCancellables)
  }
  
  open override func configure<Member: ManagedMemberViewModel>(
    _ member: Member,
    theme: MemberListCellComponentTheme
  ) {
    primaryImageView?.imageView
      .configure(
        member.userViewModel.userAvatarUrlPublisher,
        placeholder: theme.itemTheme.imageView.$localImage.eraseToAnyPublisher(),
        cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.imageView, cancelIn: &contentCancellables)
    
    primaryLabel?.labelView
      .configure(
        member.userViewModel.userNamePublisher.map({ $0 }).eraseToAnyPublisher(), cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.primaryLabel, cancelIn: &contentCancellables)
  }
}
