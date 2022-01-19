//
//  MessageListComponentViewModel.swift
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

import Foundation
import UIKit
import CoreData
import Combine

import PubNubChat
import PubNub

extension ChatProvider
  where ManagedEntities: ChatViewModels,
        ManagedEntities: ManagedChatEntities,
        ManagedEntities.Channel.MemberViewModel == ManagedEntities.Member {

  open func messagesFrom(pubnubChannelId: String) -> NSFetchedResultsController<ManagedEntities.Message> {

    let request = ManagedEntities.Message.messagesBy(pubnubChannelId: pubnubChannelId)

    request.sortDescriptors = [
      NSSortDescriptor(key: "dateCreated", ascending: true)
    ]

    request.relationshipKeyPathsForPrefetching = ["sender"]
    
    return fetchedResultsControllerProvider(
      fetchRequest: request,
      sectionKeyPath: nil,
      cacheName: nil
    )
  }

  open func messageListComponentViewModel(
    pubnubChannelId: String,
    customTheme: MessageListComponentTheme? = nil,
    customInputTheme: MessageInputComponentTheme? = nil
  ) throws -> MessageListComponentViewModel<ModelData, ManagedEntities> {
    let sender = try fetchCurrentUser()
    
    guard let channel = try fetchChannel(byPubNubId: pubnubChannelId) else {
      throw ChatError.missingRequiredData
    }
    
    return MessageListComponentViewModel(
      provider: self,
      author: sender,
      selectedChannel: channel,
      fetchedMessages: messagesFrom(pubnubChannelId: pubnubChannelId),
      messageInputComponent: messageInputComponentViewModel(
        channel: channel,
        customTheme: customInputTheme
      ),
      componentTheme: customTheme ?? themeProvider.template.messageListComponent
    )
  }
}

open class MessageListComponentViewModel<ModelData, ManagedEntities>:
    ManagedEntityListViewModel<ModelData, ManagedEntities>,
    ReloadDatasourceItemDelegate
  where ModelData: ChatCustomData,
        ManagedEntities: ChatViewModels,
        ManagedEntities: ManagedChatEntities,
        ManagedEntities.Channel.MemberViewModel == ManagedEntities.Member
{

  // Managed Data
  public let author: ManagedEntities.User
  public let selectedChannel: ManagedEntities.Channel
  public private(set) var fetchedEntities: NSFetchedResultsController<ManagedEntities.Message>

  // Overscroll History Fetch
  @Published public var oldestMessageTimetoken: Timetoken = .max
  
  // Message Input VM
  public let messageInputViewModel: MessageInputComponentViewModel<ModelData, ManagedEntities>
    
  // Typing Indicator
  let typingIndicatorSectionId = "TypingIndicatorSectionId"

  @Published public var componentTheme: MessageListComponentTheme
  
  public init(
    provider: ChatProvider<ModelData,ManagedEntities>,
    author: ManagedEntities.User,
    selectedChannel: ManagedEntities.Channel,
    fetchedMessages: NSFetchedResultsController<ManagedEntities.Message>,
    messageInputComponent: MessageInputComponentViewModel<ModelData, ManagedEntities>,
    componentTheme: MessageListComponentTheme? = nil
  ) {
    self.author = author
    self.selectedChannel = selectedChannel
    self.fetchedEntities = fetchedMessages
    self.componentTheme = componentTheme ?? provider.themeProvider.template.messageListComponent
    
    self.messageInputViewModel = messageInputComponent
    
    super.init(provider: provider)

    self.fetchedEntities.delegate = self
    
    // Keep the oldest message of the channel updated
    selectedChannel.oldestMessagePublisher
      .sink { [weak self] value in
        self?.oldestMessageTimetoken = value?.pubnubId ?? Timetoken.max
      }
      .store(in: &cancellables)
  }

  // MARK: - Component View Setup
  open override func configuredComponentView() -> ComponentViewController {
    
    let messageListTheme = provider.themeProvider.template
      .messageListComponent
    
    // Setup Message Input Listeners
    let messageInputComponent = messageInputViewModel.configuredComponentView(cancelStore: &cancellables)
    
    var localCancellables = Set<AnyCancellable>()
    messageListTheme.$messageInputComponent.sink { inputTheme in
      messageInputComponent
        .theming(inputTheme, cancelIn: &localCancellables)
    }.store(in: &cancellables)
    cancellables.formUnion(localCancellables)

    let controller = ChatViewController(
      viewModel: self,
      collectionViewType: messageListTheme.collectionViewTheme.viewType,
      collectionViewLayout: messageListTheme.collectionViewTheme.layoutType.create(
        usingSupplimentaryItems: layoutShouldContainSupplimentaryViews
      ),
      messageInputComponent: messageInputComponent
    )

    // Configure Message Input
    messageInputViewModel.$typingMemberIds
      .sink { [weak self] memberIds in
        if memberIds.isEmpty {
          self?.removeTypingIndicator()
        } else {
          self?.addTypingIndicator()
        }
      }.store(in: &cancellables)
    
    // Register Cells
    messageListTheme.authorItemTheme.cellType
      .registerCell(controller.collectionView)
    messageListTheme.authorItemTheme.richMessageContentCellTypes.forEach {
      $1.registerCell(controller.collectionView)
    }
    
    messageListTheme.incomingItemTheme.cellType
      .registerCell(controller.collectionView)
    messageListTheme.incomingItemTheme.richMessageContentCellTypes.forEach {
      $1.registerCell(controller.collectionView)
    }
    
    messageListTheme.typingIndicatorCellTheme.cellType
      .registerCell(controller.collectionView)
    
    provider.themeProvider.template.$messageListComponent
      .sink { [weak controller] theme in
        controller?.view.backgroundColor = theme.backgroundColor
      }
      .store(in: &cancellables)
    
    configureCollectionView(
      controller.collectionView,
      theme: messageListTheme.collectionViewTheme
    )

    return controller
  }
  
  // MARK: - Navigation
  public var leftBarButtonNavigationItems: ((UIViewController, MessageListComponentViewModel<ModelData, ManagedEntities>?) -> ([UIBarButtonItem]))?
  public var rightBarButtonNavigationItems: (
    (UIViewController, MessageListComponentViewModel<ModelData, ManagedEntities>?) -> ([UIBarButtonItem])
  )? = { controller, viewModel in
    guard let viewModel = viewModel,
          let memberCountTheme = viewModel.componentTheme
                .navigationBar.barButtonThemes["memberPresenceCount"] else { return [] }

    
    let barButton = memberCountTheme.viewType.init(action: { [weak viewModel, weak controller] button in
        // Prepare Message List View
        guard let selectedChannelId = viewModel?.selectedChannel.pubnubId,
              let component = viewModel?.provider
                .memberListComponentViewModel(channelId: selectedChannelId)
                .configuredComponentView() else { return }
        
        // Display it from the current controller in the primary content view
        controller?.show(component, sender: nil)
      }
    )
    
    barButton.button.theming(memberCountTheme, cancelIn: &viewModel.cancellables)

    viewModel.selectedChannel.presentMemberCountPublisher
      .sink { [weak barButton] presenceCount in
        barButton?.button.setTitle("\(presenceCount)", for: .normal)
      }
      .store(in: &viewModel.cancellables)
    
    return [barButton]
  }
  public var customNavigationTitleView: (
    (MessageListComponentViewModel<ModelData, ManagedEntities>?) -> UIView
  )?
  
  @objc
  public func rightBarButtonItemPressed(sender: UIBarButtonItem) {}

  public var customNavigationTitleString: (
    (MessageListComponentViewModel<ModelData, ManagedEntities>?) -> AnyPublisher<String?, Never>?
  )? = { viewModel in
    return viewModel?.selectedChannel.channelNamePublisher.map({ $0 }).eraseToAnyPublisher()
  }
  
  open override func viewController(_ controller: UIViewController, navigationItem: UINavigationItem) {
    super.viewController(controller, navigationItem: navigationItem)
    
    // Theming
    navigationItem.theming(componentTheme.navigationBar, cancelIn: &cancellables)
    
    // Set the Title
    navigationItemTitle(navigationItem)
    
    // Set the right navigation Item
    navigationItem.leftBarButtonItems = leftBarButtonNavigationItems?(controller, self)
    navigationItem.rightBarButtonItems = rightBarButtonNavigationItems?(controller, self)
  }
  
  open func navigationItemTitle(_ navigationItem: UINavigationItem) {
    if let titleString = customNavigationTitleString?(self) {
      titleString.weakAssign(to: \.title, on: navigationItem).store(in: &cancellables)
    } else if let titleView = customNavigationTitleView?(self) {
      navigationItem.titleView = titleView
    }
  }
  
  // MARK: - Actions
  
  public var componentDidLoad: (
    (UIViewController, MessageListComponentViewModel<ModelData, ManagedEntities>?) -> Void
  )?
  
  open override func viewControllerDidLoad(_ controller: UIViewController) {
    super.viewControllerDidLoad(controller)
    
    componentDidLoad?(controller, self)
  }
  
  public var componentWillAppear: (
    (UIViewController, MessageListComponentViewModel<ModelData, ManagedEntities>?) -> Void
  )?
  
  open override func viewController(_ controller: UIViewController, viewWillAppear animated: Bool) {
    super.viewController(controller, viewWillAppear: animated)
    
    componentWillAppear?(controller, self)
  }
  
  public var componentWillDisappear: ((UIViewController, MessageListComponentViewModel<ModelData, ManagedEntities>?) -> Void)?
  
  open override func viewController(_ controller: UIViewController, viewWillDisappear animated: Bool) {
    super.viewController(controller, viewWillDisappear: animated)
    
    componentWillDisappear?(controller, self)
  }

  // MARK: - Features
  
  // MARK: Refresh Top
  open override func performRemoteCollectionViewData(_ completion: (() -> Void)?) {    
    self.provider.dataProvider.syncRemoteMessages(
      MessageHistoryRequest(
        channels: [selectedChannel.pubnubChannelID],
        start: oldestMessageTimetoken == .max ? nil : oldestMessageTimetoken
      )
    ) { result in
      switch result {
      case .success((_, _)):
        completion?()
      case let .failure(error):
        PubNub.log.error("Error Performing Remote Collection Update \(error)")
        completion?()
      }
    }
  }
  
  // MARK: Scroll to Bottom
  
  // MARK: Typing Indicator

  open func typingIndicatorCell(
    collectionView: UICollectionView,
    indexPath: IndexPath,
    for channel: ManagedEntities.Channel
  ) throws -> UICollectionViewCell {
    let cellTheme = componentTheme.typingIndicatorCellTheme
    
    let cell = try cellTheme.cellType.dequeue(collectionView, for: indexPath)
    
    cell.theming(componentTheme.typingIndicatorCellTheme)
        
    cell.configure(
      channel,
      typingMemberIds: messageInputViewModel.$typingMemberIds.eraseToAnyPublisher(),
      theme: cellTheme
    )

    return cell
  }
  
  func removeTypingIndicator() {
    guard var snapshot = dataSource?.snapshot() else { return }
    
    snapshot.deleteItems([selectedChannel.objectID])
    
    dataSnapshotQueue.async { [dataSource] in
      dataSource?.apply(
        snapshot, animatingDifferences: false
      )
    }
  }
  
  func addTypingIndicator() {
    guard var snapshot = dataSource?.snapshot() else { return }
    
    if snapshot.indexOfSection(typingIndicatorSectionId) == nil {
      snapshot.appendSections([typingIndicatorSectionId])
    }
    
    if snapshot.indexOfItem(selectedChannel.objectID) == nil {
      snapshot.appendItems([selectedChannel.objectID], toSection: typingIndicatorSectionId)
    }
    
    dataSnapshotQueue.async { [dataSource] in
      dataSource?.apply(
        snapshot, animatingDifferences: true
      )
    }
  }

  // MARK: - Cell Provider
  
  open override func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for channel: ManagedEntities.Channel
  ) throws -> UICollectionViewCell {
    return try typingIndicatorCell(
      collectionView: collectionView,
      indexPath: indexPath,
      for: channel
    )
  }

  open override func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for message: ManagedEntities.Message
  ) throws -> UICollectionViewCell {

    let cellTheme = message.userViewModel.pubnubId == provider.currentUserId ?
      componentTheme.authorItemTheme : componentTheme.incomingItemTheme
    
    switch message.messageContentType {
    case .text:
      return try configureTextMessgeCell(
        collectionView, at: indexPath, cellType: cellTheme.cellType,
        for: message, theme: cellTheme
      )
    case .link:
      if let linkCellType = cellTheme.richMessageContentCellTypes[.link] {
        return try configureLinkMessgeCell(
          collectionView, at: indexPath, cellType: linkCellType,
          for: message, theme: cellTheme
        )
      } else {
        // Fall back to Text
        return try configureTextMessgeCell(
          collectionView, at: indexPath, cellType: cellTheme.cellType,
          for: message, theme: cellTheme
        )
      }
    case .imageRemote:
      if let linkCellType = cellTheme.richMessageContentCellTypes[.imageRemote] {
        return try configureImageRemoteMessgeCell(
          collectionView, at: indexPath, cellType: linkCellType,
          for: message, theme: cellTheme
        )
      } else {
        // Fall back to Text
        return try configureTextMessgeCell(
          collectionView, at: indexPath, cellType: cellTheme.cellType,
          for: message, theme: cellTheme
        )
      }
    case .custom:
      if let linkCellType = cellTheme.richMessageContentCellTypes[.custom] {
        return try configureCustomMessgeCell(
          collectionView, at: indexPath, cellType: linkCellType,
          for: message, theme: cellTheme
        )
      } else {
        // Fall back to Text
        return try configureTextMessgeCell(
          collectionView, at: indexPath, cellType: cellTheme.cellType,
          for: message, theme: cellTheme
        )
      }
    }
  }
  
  // MARK: Custom Cell Types

  open func configureTextMessgeCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    cellType: CollectionViewCellComponent.Type,
    for message: ManagedEntities.Message,
    theme: MessageListCellComponentTheme
  ) throws -> CollectionViewCellComponent {
    let cell = try cellType.dequeue(collectionView, for: indexPath)
    
    cell.reloadId = message.managedObjectId
    cell.reloadDelegate = self
    
    cell.theming(theme)

    cell.configure(message, theme: theme)
    
    return cell
  }
  

  open func configureLinkMessgeCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    cellType: CollectionViewCellComponent.Type,
    for message: ManagedEntities.Message,
    theme: MessageListCellComponentTheme
  ) throws -> CollectionViewCellComponent {
    
    let cell = try cellType.dequeue(collectionView, for: indexPath)
    
    cell.reloadId = message.managedObjectId
    cell.reloadDelegate = self
    
    cell.theming(theme)

    cell.configure(message, theme: theme)
    
    return cell
  }
  
  open func configureImageRemoteMessgeCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    cellType: CollectionViewCellComponent.Type,
    for message: ManagedEntities.Message,
    theme: MessageListCellComponentTheme
  ) throws -> CollectionViewCellComponent {
    let cell = try cellType.dequeue(collectionView, for: indexPath)
    
    cell.reloadId = message.managedObjectId
    cell.reloadDelegate = self
    
    cell.theming(theme)
    
    cell.configure(message, theme: theme)
    
    return cell
  }

  open func configureCustomMessgeCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    cellType: CollectionViewCellComponent.Type,
    for message: ManagedEntities.Message,
    theme: MessageListCellComponentTheme
  ) throws -> CollectionViewCellComponent {
    let cell = try cellType.dequeue(collectionView, for: indexPath)
    
    cell.reloadId = message.managedObjectId
    cell.reloadDelegate = self
    
    cell.theming(theme)

    cell.configure(message, theme: theme)
    
    return cell
  }

  // MARK: - Fetched Results Controller & Delegate

  public var configureFetchedResultsController: ((NSFetchedResultsController<ManagedEntities.Message>) -> Void)?
  
  open override func performFetch() {
    configureFetchedResultsController?(fetchedEntities)
    
    do {
      try fetchedEntities.performFetch()
    } catch {
      preconditionFailure("Fetched Results Controller failed to perform fetch: \(error)")
    }
  }

  // MARK: - AsyncReloadDelegate

  open func reloadAsyncContainer(_ identifier: NSManagedObjectID?) {
    guard let objectId = identifier, var refreshSnapshot = dataSource?.snapshot() else { return }
    
    dataSnapshotQueue.async { [dataSource] in
      refreshSnapshot.reloadItems([objectId])
      dataSource?.apply(refreshSnapshot)
    }
  }
}
