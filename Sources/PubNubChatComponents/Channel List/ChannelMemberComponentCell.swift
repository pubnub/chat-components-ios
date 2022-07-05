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
 
  open var primaryImageView: ImageComponentView?
  open var primaryLabel: PubNubLabelComponentView?
  open var secondaryLabel: PubNubLabelComponentView?
  
  public let contentContainer = UIStackView()
  
  open override func setupSubviews() {
    super.setupSubviews()
    
    let avatarView = PubNubAvatarComponentView(frame: bounds)
    self.primaryLabel = PubNubLabelComponentView(frame: bounds)
    self.secondaryLabel = PubNubLabelComponentView(frame: bounds)

    // Arrange Top Container
    contentContainer.axis = .vertical
    contentContainer.alignment = .leading
    contentContainer.addArrangedSubview(primaryLabel)
    contentContainer.addArrangedSubview(secondaryLabel?.priorityFill(axis: .vertical))

    stackView.alignment = .center
    stackView.spacing = 5.0
    stackView.addArrangedSubview(avatarView)
    stackView.addArrangedSubview(contentContainer)
    
    avatarView.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.75).isActive = true
    avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor).isActive = true
  
    primaryImageView = avatarView
  }
  
  // MARK: - Configure Data
  
  open override func configure<Channel: ManagedChannelViewModel>(
    _ channel: Channel,
    theme: ChannelListCellComponentTheme
  ) {
    primaryImageView?
      .configure(
        channel.channelAvatarUrlPublisher,
        placeholder: theme.itemTheme.imageView.$localImage.eraseToAnyPublisher(),
        cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.imageView, cancelIn: &contentCancellables)
    
    primaryLabel?
      .configure(
        channel.channelNamePublisher.map({ $0 }).eraseToAnyPublisher(), cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.primaryLabel, cancelIn: &contentCancellables)
    
    secondaryLabel?
      .configure(
        channel.channelDetailsPublisher, cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.secondaryLabel, cancelIn: &contentCancellables)
  }
  
  open override func configure<Member: ManagedMemberViewModel>(
    _ member: Member,
    theme: MemberListCellComponentTheme
  ) {
    primaryImageView?
      .configure(
        member.userViewModel.userAvatarUrlPublisher,
        placeholder: theme.itemTheme.imageView.$localImage.eraseToAnyPublisher(),
        cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.imageView, cancelIn: &contentCancellables)
    
    primaryLabel?
      .configure(
        member.userViewModel.userNamePublisher.map({ $0 }).eraseToAnyPublisher(), cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.primaryLabel, cancelIn: &contentCancellables)
  }
}
