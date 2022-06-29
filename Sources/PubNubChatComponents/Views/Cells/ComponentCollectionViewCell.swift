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

import PubNub

/// Base class for CollectionView Cell
open class CollectionViewCellComponent: UICollectionViewCell, ReloadCellDelegate {

  // MARK: Properties
  
  public var cancellables = Set<AnyCancellable>()
  public var contentCancellables = Set<AnyCancellable>()
  
  // Default Subviews
  public lazy var stackView = UIStackView(frame: bounds)
  
  @Published public var cellAlignment: UICollectionViewCell.Alignment = .leading
  
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
    contentView.addSubview(stackView)
    insetsLayoutMarginsFromSafeArea = false
    layoutMargins = .zero
    
    contentView.insetsLayoutMarginsFromSafeArea = false
    contentView.layoutMargins = .zero
    
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.leadingAnchor
      .constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
    stackView.trailingAnchor
      .constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    stackView.topAnchor
      .constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
    stackView.bottomAnchor
      .constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
  }
  
  // MARK: - Resuse
  
  public override func prepareForReuse() {
    super.prepareForReuse()

    contentCancellables.forEach { $0.cancel() }
  }
  
  // MARK: - UICollectionViewLayoutAttributes
  
  public override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
    return super.preferredLayoutAttributesFitting(layoutAttributes)
  }
  
  public override func apply(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) {
    
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
}
/// Base `Message` cell that can be subclassed based on payload type
open class MessageListItemCell: CollectionViewCellComponent {
  
  // MARK: Subviews
  
  open var authorAvatarView: ImageComponentView?
  open var primaryLabel: LabelComponentView?
  open var secondaryLabel: LabelComponentView?
  open var tertiaryLabel: LabelComponentView?
  open var quaternaryLabel: LabelComponentView?
  
  // Text
  open var bubbleContainer: BubbleContainerView?
  open var messageTextContent: TextComponentView?
  
  public var contentEdgeSpacing: CGFloat = .zero
  
  // MARK: UIStack Subview
  public let topContainerStack = UIStackView()
  public let contentContainer = UIStackView()
  
  public var customImageViewSpacing: CGFloat {
    guard let imageView = authorAvatarView else { return 0 }
    return stackView.customSpacing(after: imageView)
  }
  
  // MARK: - UICollectionViewLayoutAttributes
  
  public override func setupSubviews() {
    super.setupSubviews()
    
    self.authorAvatarView = PubNubAvatarComponentView(frame: bounds)
    self.primaryLabel = PubNubLabelComponentView(frame: bounds)
    self.secondaryLabel = PubNubLabelComponentView(frame: bounds)
    self.bubbleContainer = BubbleContainerView(frame: bounds)
    self.messageTextContent = TextComponentView(frame: bounds)
    
    // Arrange Top Container
    topContainerStack.isLayoutMarginsRelativeArrangement = true
    topContainerStack.layoutMargins = .init(
      top: .zero, left: -contentEdgeSpacing + 15.0, bottom: .zero, right: .zero
    )
    topContainerStack.addArrangedSubview(primaryLabel)
    topContainerStack.setCustomSpacing(5.0, after: primaryLabel)
    topContainerStack.addArrangedSubview(secondaryLabel)

    contentContainer.axis = .vertical
    $cellAlignment.sink { [weak self] newAlignment in
      self?.contentContainer.alignment = newAlignment.stackViewAlignment
    }.store(in: &cancellables)
    contentContainer.isLayoutMarginsRelativeArrangement = true
    contentContainer.addArrangedSubview(topContainerStack)
    contentContainer.addArrangedSubview(bubbleContainer)

    authorAvatarView?.heightAnchor.constraint(equalToConstant: 30).isActive = true
    authorAvatarView?.widthAnchor.constraint(equalToConstant: 30).isActive = true
    
    stackView.alignment = .bottom
    stackView.addArrangedSubview(authorAvatarView)
    stackView.setCustomSpacing(contentEdgeSpacing, after: authorAvatarView)
    stackView.addArrangedSubview(contentContainer)
  }
  
  // MARK: - Configure Message
  open override func configure<Message: ManagedMessageViewModel>(
    _ message: Message,
    theme: MessageListCellComponentTheme
  ) {
    theme.$alignment.sink { [weak self] newAlignment in
      self?.cellAlignment = newAlignment
    }.store(in: &contentCancellables)
    
    authorAvatarView?
      .configure(
        message.userViewModel.userAvatarUrlPublisher,
        placeholder: theme.itemTheme.imageView.$localImage.eraseToAnyPublisher(),
        cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.imageView, cancelIn: &contentCancellables)

    primaryLabel?
      .configure(message.userViewModel.userNamePublisher, cancelIn: &contentCancellables)
      .theming(theme.itemTheme.primaryLabel, cancelIn: &contentCancellables)
    
    secondaryLabel?
      .configure(
        message.messageDateCreatedPublisher,
        formatter: theme.dateFormatter,
        cancelIn: &contentCancellables
      )
      .theming(theme.itemTheme.secondaryLabel, cancelIn: &contentCancellables)

    messageTextContent?.textView
      .configure(message.messageTextPublisher, cancelIn: &contentCancellables)
      .theming(theme.contentTextTheme, cancelIn: &contentCancellables)

    bubbleContainer?
      .configure(contentView: messageTextContent!)
    bubbleContainer?
      .theming(theme.bubbleContainerTheme, cancelIn: &contentCancellables)
  }
}

open class MessageTextContentCell: MessageListItemCell {
  
  public lazy var textContent = TextComponentView(frame: bounds)
  
}
