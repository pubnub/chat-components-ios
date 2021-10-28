//
//  ChannelListComponentViewModel.swift
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
        ManagedEntities.Member.ChannelViewModel == ManagedEntities.Channel,
        ManagedEntities.Channel.MemberViewModel == ManagedEntities.Member
{
  open func channelMembershipsFrom(
    userId: String, sectionedByType: Bool
  ) -> NSFetchedResultsController<ManagedEntities.Member> {
    
    let request = ManagedEntities.Member.membershipsBy(userId: userId)
    
    request.sortDescriptors = [
      NSSortDescriptor(key: "channel.type", ascending: false),
      NSSortDescriptor(key: "channel.name", ascending: true)
    ]
    request.relationshipKeyPathsForPrefetching = ["channel"]
    
    return fetchedResultsControllerProvider(
      fetchRequest: request,
      sectionKeyPath: sectionedByType ? "channel.type": nil,
      cacheName: nil
    )
  }
  
  open func senderMembershipsChanneListComponentViewModel(
    sectionedByType: Bool = true,
    customTheme: ChannelListComponentTheme? = nil
  ) -> ChannelListComponentViewModel<ModelData, ManagedEntities> {
    return ChannelListComponentViewModel(
      provider: self,
      fetchedEntities: channelMembershipsFrom(userId: currentUserId, sectionedByType: sectionedByType),
      componentTheme: customTheme ?? self.themeProvider.template.channelListComponent
    )
  }
}

open class ChannelListComponentViewModel<ModelData, ManagedEntities>:
    ManagedEntityListViewModel<ModelData, ManagedEntities>,
    ReloadDatasourceItemDelegate
  where ModelData: ChatCustomData,
      ManagedEntities: ChatViewModels,
      ManagedEntities: ManagedChatEntities,
      ManagedEntities.Member.ChannelViewModel == ManagedEntities.Channel,
      ManagedEntities.Channel.MemberViewModel == ManagedEntities.Member
{

  public private(set) var fetchedEntities: NSFetchedResultsController<ManagedEntities.Member>
  
  @Published public var componentTheme: ChannelListComponentTheme
  
  public init(
    provider: ChatProvider<ModelData,ManagedEntities>,
    fetchedEntities: NSFetchedResultsController<ManagedEntities.Member>,
    componentTheme: ChannelListComponentTheme? = nil
  ) {
    self.fetchedEntities = fetchedEntities
    self.componentTheme = componentTheme ?? provider.themeProvider.template.channelListComponent
    
    super.init(provider: provider)
    
    self.layoutShouldContainSupplimentaryViews = fetchedEntities.sectionNameKeyPath != nil
    self.fetchedEntities.delegate = self
  }
  
  // MARK: - Component View Setup
  
  open override func configuredComponentView() -> ComponentViewController {
    
    let channelListTheme = provider.themeProvider.template
      .channelListComponent
    
    let controller = CollectionViewComponent(
      viewModel: self,
      collectionViewType: channelListTheme.collectionViewTheme.viewType,
      collectionViewLayout: channelListTheme.collectionViewTheme.layoutType.create(
          usingSupplimentaryItems: layoutShouldContainSupplimentaryViews
        )
      )
    self.controller = controller

    channelListTheme.cellTheme.cellType.registerCell(controller.collectionView)

    configureCollectionView(
      controller.collectionView,
      theme: channelListTheme.collectionViewTheme
    )
    
    return controller
  }
  
  // MARK: - Default View Controller

  public var leftBarButtonNavigationItems: (
    (UIViewController, ChannelListComponentViewModel<ModelData, ManagedEntities>?) -> [UIBarButtonItem]
  )?
  public var rightBarButtonNavigationItems: (
    (UIViewController, ChannelListComponentViewModel<ModelData, ManagedEntities>?) -> [UIBarButtonItem]
  )?
  
  public var customNavigationTitleView: (
    (ChannelListComponentViewModel<ModelData, ManagedEntities>?) -> UIView?
  )? = { viewModel in
    guard let sender = try? viewModel?.provider.fetchCurrentUser(),
          let theme = viewModel?.componentTheme.navigationBar.customTitleView else { return nil }
 
    let titleView = UserInlineDetailComponentView()
      
    titleView.configure(sender, theme: theme)
    
    return titleView
  }
  
  public var customNavigationTitleString: (
    (ChannelListComponentViewModel<ModelData, ManagedEntities>?) -> AnyPublisher<String?, Never>?
  )?
  
  open override func viewController(_ controller: UIViewController, navigationItem: UINavigationItem) {
    super.viewController(controller, navigationItem: navigationItem)

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
    (UIViewController, ChannelListComponentViewModel<ModelData, ManagedEntities>?) -> Void
  )? = { controller, viewModel in
    guard let sender = try? viewModel?.provider.fetchCurrentUser() else { return }
    
    // Subscribe to current user memberships
    viewModel?.provider.pubnubProvider.subscribe(.init(channels: sender.membershipIds, withPresence: true))
  }
  
  open override func viewControllerDidLoad(_ controller: UIViewController) {
    super.viewControllerDidLoad(controller)
    
    componentDidLoad?(controller, self)
  }
  
  public var componentWillAppear: (
    (UIViewController, ChannelListComponentViewModel<ModelData, ManagedEntities>?) -> Void
  )?

  open override func viewController(_ controller: UIViewController, viewWillAppear animated: Bool) {
    super.viewController(controller, viewWillAppear: animated)
    
    componentWillAppear?(controller, self)
  }
  
  public var componentWillDisappear: ((UIViewController, ChannelListComponentViewModel<ModelData, ManagedEntities>?) -> Void)?
  
  open override func viewController(_ controller: UIViewController, viewWillDisappear animated: Bool) {
    super.viewController(controller, viewWillDisappear: animated)
    
    componentWillDisappear?(controller, self)
  }

public var didSelectChannel: (
  (UIViewController, ChannelListComponentViewModel<ModelData, ManagedEntities>?, ChatChannel<ModelData.Channel>) -> Void
)? = { (controller, viewModel, channel) in
  
  // Prepare Message List View
  guard let component = try? viewModel?.provider
    .messageListComponentViewModel(pubnubChannelId: channel.id)
          .configuredComponentView() else { return }

  // Display it from the current controller in the primary content view
  controller.show(component, sender: nil)
}

  open override func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    
    guard let objectId = dataSource?.itemIdentifier(for: indexPath),
          let controller = self.controller,
          let member = try? provider.fetchMember(byObjectId: objectId) else { return }

    didSelectChannel?(controller, self, member.managedChannel.convert())
  }
  
  // MARK: - Cell Provider

  open override func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for member: ManagedEntities.Member
  ) throws -> UICollectionViewCell {
    
    let cell = try componentTheme.cellTheme.cellType
      .dequeue(collectionView, for: indexPath)
    
    cell.reloadId = member.managedObjectId
    cell.reloadDelegate = self
    
    cell.theming(componentTheme.cellTheme)
    
    cell.configure(member.channelViewModel, theme: componentTheme.cellTheme)
    
    return cell
  }

  // MARK: - Supplimentary View

  public var channelSectionTitles = [
    BasicComponentViewModel(primaryLabel: "Channels"),
    BasicComponentViewModel(primaryLabel: "Direct Chats")
  ]

  open override func configureHeaderView(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath
  ) throws -> UICollectionReusableView? {
    
    let header = try componentTheme.collectionViewTheme
      .headerType.dequeueHeader(collectionView, at: indexPath)

    header.configure(
      channelSectionTitles[indexPath.section],
      theme: componentTheme.sectionHeaderTheme
    )

    return header
  }
  
  // MARK: - Fetched Results Controller & Delegate
  
  public var configureFetchedResultsController: ((NSFetchedResultsController<ManagedEntities.Member>) -> Void)?
  
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
