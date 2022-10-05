//
//  ComponentCollectionViewCell.swift
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

import ChatLayout

import PubNub

/// Base class for CollectionView Cell
open class CollectionViewCellComponent: UICollectionViewCell, ReloadCellDelegate {

  // MARK: Properties
  
  public var cancellables = Set<AnyCancellable>()
  public var contentCancellables = Set<AnyCancellable>()
  
  // Default Subviews
  // More information why StackViews are wrapped inside Views: https://stackoverflow.com/a/38237799
  public lazy var cellContainer = UIStackContainerView()
  
  // ReloadCellDelegate

  public var reloadId: NSManagedObjectID?
  public weak var reloadDelegate: ReloadDatasourceItemDelegate?

  // MARK: - Initializers

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupSubviews()
  }

  open func setupSubviews() {
    contentView.addSubview(cellContainer)
    
    cellContainer.translatesAutoresizingMaskIntoConstraints = false
    cellContainer.leadingAnchor
      .constraint(equalTo: contentView.leadingAnchor).isActive = true
    cellContainer.topAnchor
      .constraint(equalTo: contentView.topAnchor).isActive = true
    
    cellContainer.bottomAnchor
      .constraint(equalTo: contentView.bottomAnchor)
      .priority(.overrideRequire)
      .isActive = true
    cellContainer.trailingAnchor
      .constraint(equalTo: contentView.trailingAnchor)
      .priority(.overrideRequire)
      .isActive = true
  }
  
  // MARK: - Resuse
  
  public override func prepareForReuse() {
    super.prepareForReuse()

    contentCancellables.forEach { $0.cancel() }
  }
  
  // MARK: - UICollectionViewLayoutAttributes
  
  open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    return super.preferredLayoutAttributesFitting(layoutAttributes)
  }
  
  open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
  }
  
  public override func willTransition(
    from oldLayout: UICollectionViewLayout,
    to newLayout: UICollectionViewLayout
  ) {
    
  }
  
  public override func didTransition(
    from oldLayout: UICollectionViewLayout,
    to newLayout: UICollectionViewLayout
  ) {
    
  }
  
  // MARK: CollectionView Inversion

  public static func registerCell(_ collectionView: UICollectionView) {
    collectionView.register(cell: Self.self)
  }
  
  public static func dequeue(
    _ collectionView: UICollectionView,
    for indexPath: IndexPath
  ) throws -> CollectionViewCellComponent {
    return try collectionView.dequeueComponent(Self.self, for: indexPath)
  }
  
  // MARK: - ReloadCellDelegate
  
  public func reloadComponentCell() {
    guard let reloadId = reloadId else {
      PubNub.log.warn("CollectionViewCellComponent could not reload without id")
      return
    }
    
    self.reloadDelegate?.reloadAsyncContainer(reloadId)
  }
  
  // MARK: - Base Managed Object View Models
  
  open func configure<Message: ManagedMessageViewModel>(
    _ message: Message,
    theme: MessageListCellComponentTheme
  ) {
    
  }
  
  open func configure<Channel: ManagedChannelViewModel>(
    _ channel: Channel,
    theme: ChannelListCellComponentTheme
  ) {
    
  }
  
  open func configure<Member: ManagedMemberViewModel>(
    _ member: Member,
    theme: MemberListCellComponentTheme
  ) {
    
  }
  
  // Typing Indicators
  open func configure<Channel: ManagedChannelViewModel>(
    _ channel: Channel,
    typingMemberIds: AnyPublisher<Set<String>, Never>,
    theme: TypingIndicatorCellTheme
  ) {
    
  }
  
  // Message Reaction List
  open func configure<Message: ManagedMessageViewModel, User: ManagedUserViewModel>(
    _ message: Message,
    currentUser: User,
    reactionProvider: ReactionProvider,
    onTapAction: ((MessageReactionButtonComponent?, Message, (() -> Void)?) -> Void)?
  ) {

  }
}

open class MessageCollectionViewCellComponent: CollectionViewCellComponent {
  
  public weak var delegate: ContainerCollectionViewCellDelegate?

  public override func prepareForReuse() {
    super.prepareForReuse()

    delegate?.prepareForReuse()
  }
  
  open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
      return super.preferredLayoutAttributesFitting(layoutAttributes)
    }
    delegate?.apply(chatLayoutAttributes)
    let resultingLayoutAttributes: ChatLayoutAttributes
    if let preferredLayoutAttributes = delegate?.preferredLayoutAttributesFitting(chatLayoutAttributes) {
      resultingLayoutAttributes = preferredLayoutAttributes
    } else if let chatLayoutAttributes = super.preferredLayoutAttributesFitting(chatLayoutAttributes) as? ChatLayoutAttributes {
      delegate?.modifyPreferredLayoutAttributesFitting(chatLayoutAttributes)
      resultingLayoutAttributes = chatLayoutAttributes
    } else {
      resultingLayoutAttributes = chatLayoutAttributes
    }

    return resultingLayoutAttributes
  }
  
  open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    guard let chatLayoutAttributes = layoutAttributes as? ChatLayoutAttributes else {
      return
    }
    if layoutAttributes.size.height == .zero || layoutAttributes.size.width == .zero {
      return
    }
    super.apply(layoutAttributes)
    delegate?.apply(chatLayoutAttributes)
  }
}

/// Base `Message` cell that can be subclassed based on payload type
open class MessageListItemCell: MessageCollectionViewCellComponent {
  
  // MARK: Subviews
  
  lazy open var authorAvatarView = PubNubInlineAvatarComponentView()
  lazy open var primaryLabel = PubNubLabelComponentView()
  lazy open var secondaryLabel = PubNubLabelComponentView()
  lazy open var tertiaryLabel = PubNubLabelComponentView()
  lazy open var quaternaryLabel = PubNubLabelComponentView()
  
  // Text
  lazy public var bubbleContainer = BubbleContainerView(frame: bounds)
  lazy public var reactionListView = MessageReactionListComponent()
  
  public var contentEdgeSpacing: CGFloat = .zero
  
  // MARK: UIStack Subview
  public let topContainerStack = UIStackContainerView()
  public let contentContainer = UIStackContainerView()
  public let bottomContainer = UIStackContainerView()
  
  open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    let preferredLayout = super.preferredLayoutAttributesFitting(layoutAttributes)

    if contentView.frame.size.height != preferredLayout.bounds.size.height {
      var contentFrame = self.frame
      contentFrame.size.height = preferredLayout.size.height

      frame = contentFrame
      contentView.frame = contentFrame
    }

    return preferredLayout
  }

  // MARK: - UICollectionViewLayoutAttributes
    
  public override func setupSubviews() {
    // Layout
    topContainerStack.translatesAutoresizingMaskIntoConstraints = false
    contentContainer.translatesAutoresizingMaskIntoConstraints = false
    bottomContainer.translatesAutoresizingMaskIntoConstraints = false

    // Arrange Top Container
    topContainerStack.stackView.isLayoutMarginsRelativeArrangement = true
    topContainerStack.stackView.alignment = .leading
    topContainerStack.stackView.directionalLayoutMargins = .init(
      top: .zero, leading: -contentEdgeSpacing + 15.0, bottom: .zero, trailing: .zero
    )
    
    // Arrange Bottom Container
    bottomContainer.stackView.isLayoutMarginsRelativeArrangement = true
    bottomContainer.stackView.alignment = .leading
    bottomContainer.stackView.directionalLayoutMargins = .init(
      top: .zero, leading: -contentEdgeSpacing + 15.0, bottom: .zero, trailing: .zero
    )

    contentContainer.stackView.axis = .vertical
    contentContainer.stackView.alignment = .leading
    contentContainer.stackView.isLayoutMarginsRelativeArrangement = true

    cellContainer.axis = .horizontal
    cellContainer.distribution = .fill
    cellContainer.isLayoutMarginsRelativeArrangement = false
    
    authorAvatarView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    authorAvatarView.widthAnchor.constraint(equalToConstant: 30).isActive = true

    delegate = bubbleContainer.messageTextContent
    
    // Build the Stack Views
    topContainerStack.stackView.addArrangedSubview(primaryLabel)
    topContainerStack.stackView.setCustomSpacing(5.0, after: primaryLabel)
    topContainerStack.stackView.addArrangedSubview(secondaryLabel)
    
    bottomContainer.stackView.addArrangedSubview(reactionListView)
    
    contentContainer.stackView.addArrangedSubview(topContainerStack)
    contentContainer.stackView.addArrangedSubview(bubbleContainer)
    contentContainer.stackView.setCustomSpacing(5.0, after: bubbleContainer)
    contentContainer.stackView.addArrangedSubview(bottomContainer)

    cellContainer.addArrangedSubview(authorAvatarView)
    cellContainer.setCustomSpacing(contentEdgeSpacing, after: authorAvatarView)
    cellContainer.addArrangedSubview(contentContainer)
    
    super.setupSubviews()
  }
  
  // MARK: - Configure Message
  open override func configure<Message: ManagedMessageViewModel>(
    _ message: Message,
    theme: MessageListCellComponentTheme
  ) {
    
    theme.$alignment.sink { [weak self] newAlignment in
      self?.cellContainer.alignment = newAlignment.stackViewAlignment
    }.store(in: &contentCancellables)
    
    authorAvatarView.imageView
      .configure(
        message.userViewModel.userAvatarUrlPublisher,
        placeholder: theme.itemTheme.imageView.$localImage.eraseToAnyPublisher(),
        cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.imageView, cancelIn: &contentCancellables)

    primaryLabel.labelView
      .configure(message.userViewModel.userNamePublisher, cancelIn: &contentCancellables)
      .theming(theme.itemTheme.primaryLabel, cancelIn: &contentCancellables)

    secondaryLabel.labelView
      .configure(
        message.messageDateCreatedPublisher,
        formatter: theme.dateFormatter,
        cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.secondaryLabel, cancelIn: &contentCancellables)

    bubbleContainer.messageTextContent.textView
      .configure(message.messageTextPublisher, cancelIn: &contentCancellables)
      .theming(theme.contentTextTheme, cancelIn: &contentCancellables)

    bubbleContainer
      .theming(theme.bubbleContainerTheme, cancelIn: &contentCancellables)
  }

  open override func configure<Message: ManagedMessageViewModel, User: ManagedUserViewModel>(
    _ message: Message,
    currentUser: User,
    reactionProvider: ReactionProvider,
    onTapAction: ((MessageReactionButtonComponent?, Message, (() -> Void)?) -> Void)?
  ) {
    if message.messageActions.count == 0 {
      // Remove
      reactionListView.isHiddenSafe = true
    } else {
      // Update
      
      reactionListView.configure(
        message,
        currentUserId: currentUser.pubnubId,
        reactionProvider: reactionProvider,
        onMessageActionTap: onTapAction
      )
      
      reactionListView.isHiddenSafe = false
    }
  }
}
