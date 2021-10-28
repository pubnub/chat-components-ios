//
//  MemberListComponentViewModel.swift
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
        ManagedEntities: ManagedChatEntities
{
  
  open func userMembersFrom(
    channelId: String,
    excludingSender: Bool = false
  ) -> NSFetchedResultsController<ManagedEntities.Member> {
    
    let request = ManagedEntities.Member.membersBy(
      channelID: channelId,
      excludingUserId: excludingSender ? currentUserId : nil,
      onlyPresent: true
    )

    request.sortDescriptors = [
      NSSortDescriptor(key: "user.name", ascending: true)
    ]

    request.relationshipKeyPathsForPrefetching = ["user"]
    
    return fetchedResultsControllerProvider(
      fetchRequest: request,
      sectionKeyPath: nil,
      cacheName: nil
    )
  }
  
  open func memberListComponentViewModel(
    channelId: String,
    customTheme: MemberListComponentTheme? = nil
  ) -> MemberListComponentViewModel<ModelData, ManagedEntities> {

    return MemberListComponentViewModel(
      provider: self,
      selectedChannelId: channelId,
      fetchedEntities: userMembersFrom(channelId: channelId),
      componentTheme: customTheme ?? self.themeProvider.template.memberListComponent
    )
  }
}

open class MemberListComponentViewModel<ModelData, ManagedEntities>:
    ManagedEntityListViewModel<ModelData, ManagedEntities>,
    ReloadDatasourceItemDelegate
  where ModelData: ChatCustomData,
        ManagedEntities: ChatViewModels,
        ManagedEntities: ManagedChatEntities
{
  
  public let selectedChannelId: String
  public private(set) var fetchedEntities: NSFetchedResultsController<ManagedEntities.Member>
  
  @Published public var componentTheme: MemberListComponentTheme

  public init(
    provider: ChatProvider<ModelData,ManagedEntities>,
    selectedChannelId: String,
    fetchedEntities: NSFetchedResultsController<ManagedEntities.Member>,
    componentTheme: MemberListComponentTheme? = nil
  ) {
    self.selectedChannelId = selectedChannelId
    self.fetchedEntities = fetchedEntities
    self.componentTheme = componentTheme ?? provider.themeProvider.template.memberListComponent

    super.init(provider: provider)

    self.layoutShouldContainSupplimentaryViews = fetchedEntities.sectionNameKeyPath != nil
    self.fetchedEntities.delegate = self
  }
  
  // MARK: - Component View Setup
  
  open override func configuredComponentView() -> ComponentViewController {
    
    let memberListTheme = provider.themeProvider.template
      .memberListComponent
    
    let controller = CollectionViewComponent(
      viewModel: self,
      collectionViewType: memberListTheme.collectionViewTheme.viewType,
      collectionViewLayout: memberListTheme.collectionViewTheme.layoutType.create(
        usingSupplimentaryItems: layoutShouldContainSupplimentaryViews
      )
    )
    self.controller = controller
    
    memberListTheme.cellTheme.cellType.registerCell(controller.collectionView)

    configureCollectionView(
      controller.collectionView,
      theme: memberListTheme.collectionViewTheme
    )

    return controller
  }

  // MARK: - Default View Controller
  
  public var leftBarButtonNavigationItems: (
    (UIViewController, MemberListComponentViewModel<ModelData, ManagedEntities>?) -> [UIBarButtonItem]
  )?
  public var rightBarButtonNavigationItems: (
    (UIViewController, MemberListComponentViewModel<ModelData, ManagedEntities>?) -> [UIBarButtonItem]
  )?
  
  public var customNavigationTitleView: ((MemberListComponentViewModel<ModelData, ManagedEntities>?) -> UIView?)?
  
  public var customNavigationTitleString: ((MemberListComponentViewModel<ModelData, ManagedEntities>?) -> AnyPublisher<String?, Never>)?
  
  open override func viewController(_ controller: UIViewController, navigationItem: UINavigationItem) {
    super.viewController(controller, navigationItem: navigationItem)

    // Theming
    navigationItem.theming(componentTheme.navigationBar, cancelIn: &cancellables)
    
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
  
  public var componentDidLoad: ((UIViewController, MemberListComponentViewModel<ModelData, ManagedEntities>?) -> Void)?
  
  open override func viewControllerDidLoad(_ controller: UIViewController) {
    super.viewControllerDidLoad(controller)
    
    componentDidLoad?(controller, self)
  }
  
  public var componentWillAppear: ((UIViewController, MemberListComponentViewModel<ModelData, ManagedEntities>?) -> Void)?
  
  open override func viewController(_ controller: UIViewController, viewWillAppear animated: Bool) {
    super.viewController(controller, viewWillAppear: animated)
    
    componentWillAppear?(controller, self)
  }
  
  public var componentWillDisappear: ((UIViewController, MemberListComponentViewModel<ModelData, ManagedEntities>?) -> Void)?
  
  open override func viewController(_ controller: UIViewController, viewWillDisappear animated: Bool) {
    super.viewController(controller, viewWillDisappear: animated)
    
    componentWillDisappear?(controller, self)
  }

  public var didSelectMember: (
    (UIViewController, MemberListComponentViewModel<ModelData, ManagedEntities>?, ChatMember<ModelData>) -> Void
  )?
  
  open override func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    
    guard let objectId = dataSource?.itemIdentifier(for: indexPath),
          let controller = self.controller,
          let member = try? provider.fetchMember(byObjectId: objectId) else { return }
    
    didSelectMember?(controller, self, member.convert())
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
    
    cell.configure(member, theme: componentTheme.cellTheme)
    
    return cell
  }
  
  // MARK: - Supplimentary View
  
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
