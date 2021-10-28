//
//  ManagedEntityListViewModel.swift
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
import PubNubChat

public protocol CollectionViewComponentViewModel {

  var layoutShouldContainSupplimentaryViews: Bool { get set }
  
  func configuredComponentView() -> ComponentViewController
  func configureCollectionView(
    _ collectionView: UICollectionView,
    theme: CollectionViewComponentTheme
  )
  func viewController(_ controller: UIViewController, navigationItem: UINavigationItem)

  // View Controller Lifecycle Events
  func viewControllerDidLoad(_ controller: UIViewController)
  func viewController(_ controller: UIViewController, viewWillAppear animated: Bool)
  func viewController(_ controller: UIViewController, viewDidAppear animated: Bool)
  func viewController(_ controller: UIViewController, viewWillDisappear animated: Bool)
  func viewController(_ controller: UIViewController, viewDidDisappear animated: Bool)
}

open class ManagedEntityListViewModel<ModelData, ManagedEntities>:
    NSObject,
    CollectionViewComponentViewModel,
    NSFetchedResultsControllerDelegate,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSourcePrefetching
  where ModelData: ChatCustomData,
        ManagedEntities: ChatViewModels,
        ManagedEntities: ManagedChatEntities
{
  
  public let provider: ChatProvider<ModelData,ManagedEntities>
  public private(set) var dataSource: UICollectionViewDiffableDataSource<String, NSManagedObjectID>?
  public weak var controller: UIViewController?
  
  var cancellables = Set<AnyCancellable>()
  let dataSnapshotQueue = DispatchQueue(label: "EntityListViewModel dataSource apply queue", qos: .userInitiated)
  
  weak var collectionView: UICollectionView?
  
  init(
    provider: ChatProvider<ModelData, ManagedEntities>
  ) {
    self.provider = provider
  }
  
  // MARK: - CollectionViewComponentViewModel

  open var layoutShouldContainSupplimentaryViews = false
  
  @Published public var prefetchIndexThreshold: Int = -1

  open func configuredComponentView() -> ComponentViewController {
    return ComponentViewController(viewModel: self)
  }
  
  public var configureNavigationItems: ((ChatProvider<ModelData, ManagedEntities>, UIViewController, UINavigationItem) -> ())?
  open func viewController(_ controller: UIViewController, navigationItem: UINavigationItem) {
    configureNavigationItems?(provider, controller, navigationItem)
  }
  
  open func configureCollectionView(
    _ collectionView: UICollectionView,
    theme: CollectionViewComponentTheme
  ) {
    // Accept delegate calls
    collectionView.delegate = self
    collectionView.decelerationRate = .normal
    
    // Store value for future use
    self.collectionView = collectionView
    
    // Register Cells
    theme.headerType.registerHeader(collectionView)
    theme.footerType.registerFooter(collectionView)
  
    // Configure DataSource
    setupDatasource(collectionView, layoutComponents: theme)
    
    // Refresh Control Configuration
    collectionView.refreshControl = configureRefreshControl(theme.refreshControlTheme)

    // Configure CollectionView Theme
    collectionView.theming(theme, cancelIn: &cancellables)
    
    theme.$prefetchIndexThreshold
      .sink { [weak self] thresholdCount in
        if let thresholdCount = thresholdCount {
          self?.prefetchIndexThreshold = thresholdCount
        } else {
          self?.prefetchIndexThreshold = -1
        }
      }.store(in: &cancellables)

    // Start the FRC
    performFetch()
  }
  
  open func configureRefreshControl(_ theme: RefreshControlTheme?) -> UIRefreshControl? {
    guard let refreshTheme = theme else { return nil }

    let refreshControl = refreshTheme.viewType.init()
    
    refreshControl.theming(refreshTheme, cancelIn: &cancellables)
    
    refreshControl.addTarget(
      self,
      action: #selector(refreshCollectionViewData(sender:)),
      for: .valueChanged
    )
    
    return refreshControl
  }
  
  // MARK: - Action
  
  open func viewControllerDidLoad(_ controller: UIViewController) {
    
  }
  
  open func viewController(_ controller: UIViewController, viewWillAppear animated: Bool) {
    
  }
  
  open func viewController(_ controller: UIViewController, viewDidAppear animated: Bool) {
    
  }
 
  open func viewController(_ controller: UIViewController, viewWillDisappear animated: Bool) {
    
  }
  
  open func viewController(_ controller: UIViewController, viewDidDisappear animated: Bool) {
    
  }

  open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

  }
  
  // MARK: Fetching Remote Data
  
  @objc
  open func refreshCollectionViewData(sender: UIRefreshControl) {
    fetchRemoteCollectionViewData(sender)
  }

  open func collectionView(
    _ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath
  ) {
    if prefetchIndexThreshold >= 0, indexPath.section == 0 && indexPath.item == prefetchIndexThreshold {
      fetchRemoteCollectionViewData(collectionView.refreshControl)
    }
  }
  
  public var isFetchingData: Bool = false
  open func fetchRemoteCollectionViewData(_ sender: UIRefreshControl?) {
    if isFetchingData { return }
    
    isFetchingData = true
    
    if !(sender?.isRefreshing ?? false) {
      sender?.beginRefreshing()
    }

    performRemoteCollectionViewData { [weak self] in
      self?.isFetchingData = false
      sender?.endRefreshing()
    }
  }
  
  open func performRemoteCollectionViewData(_ completion: (() -> Void)?) {
    completion?()
  }
  
  open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {

  }
  
  open func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    
  }
  
  open func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    
  }

  // MARK: - Setup DataSource
  
  open func setupDatasource(
    _ collectionView: UICollectionView,
    layoutComponents: CollectionViewComponentTheme
  ) {
    
    // Configure Cells Views
    dataSource = .init(
      collectionView: collectionView,
      cellProvider: configureCellProvider()
    )
    
    // Configure Supplimentary Views
    dataSource?.supplementaryViewProvider = configureSupplimentaryViewProvider()
    
    collectionView.dataSource = dataSource
    collectionView.prefetchDataSource = self
  }
  
  // MARK: - Configure Cell Provider
  
  public var customCellProvider: (() -> UICollectionViewDiffableDataSource<String, NSManagedObjectID>.CellProvider)?
  
  open func configureCellProvider() -> UICollectionViewDiffableDataSource<String, NSManagedObjectID>.CellProvider {
    return customCellProvider?() ?? { [weak self] collectionView, indexPath, objectId -> UICollectionViewCell? in
      do {
        return try self?.configureCell(
          collectionView,
          at: indexPath,
          for: objectId
        )
      } catch {
        PubNub.log.error("Error Configuring cell: \(error)")
        preconditionFailure("\(String(describing: self)) could not configure the cell due to \(error)")
      }
    }
  }
  
  open func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for objectId: NSManagedObjectID
  ) throws -> UICollectionViewCell {
    // Turn NSManagedObjectID into NSManagedObject
    let object = provider.fetchManagedEntity(with: objectId)
    
    // Cast the object into a ManagedEntities type
    switch object {
    case let message as ManagedEntities.Message:
      return try configureCell(collectionView, at: indexPath, for: message)
    case let channel as ManagedEntities.Channel:
      return try configureCell(collectionView, at: indexPath, for: channel)
    case let user as ManagedEntities.User:
      return try configureCell(collectionView, at: indexPath, for: user)
    case let member as ManagedEntities.Member:
      return try configureCell(collectionView, at: indexPath, for: member)
    default:
      return try configureCell(collectionView, at: indexPath, for: object)
    }
  }
  
  open func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for channel: ManagedEntities.Channel
  ) throws -> UICollectionViewCell {
    throw ChatError.notImplemented
  }
  
  open func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for user: ManagedEntities.User
  ) throws -> UICollectionViewCell{
    throw ChatError.notImplemented
  }
  
  open func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for member: ManagedEntities.Member
  ) throws -> UICollectionViewCell {
    throw ChatError.notImplemented
  }

  open func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for message: ManagedEntities.Message
  ) throws -> UICollectionViewCell {
    throw ChatError.notImplemented
  }
  
  open func configureCell(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    for object: NSManagedObject
  ) throws -> UICollectionViewCell {
    throw ChatError.notImplemented
  }
  
  // MARK: - Configure Supplimentary Reusable View(s)
  
  public var customSupplimentaryViewProvider: (() -> UICollectionViewDiffableDataSource<String, NSManagedObjectID>.SupplementaryViewProvider)?

  open func configureSupplimentaryViewProvider() -> UICollectionViewDiffableDataSource<String, NSManagedObjectID>.SupplementaryViewProvider {
    return customSupplimentaryViewProvider?() ?? { [weak self] collectionView, elementKind, indexPath -> UICollectionReusableView? in
      do {
        return try self?.configureReusableView(collectionView, of: elementKind, at: indexPath)
      } catch {
        PubNub.log.error("Error Configuring Supplimentary View of kind `\(elementKind)`: \(error)")
        preconditionFailure("\(String(describing: self)) could not configure the Supplimentary View of kind `\(elementKind)` due to \(error)")
      }
    }
  }
  
  open func configureReusableView(
    _ collectionView: UICollectionView,
    of elementKind: String,
    at indexPath: IndexPath
  ) throws -> UICollectionReusableView? {
    switch elementKind {
    case UICollectionView.elementKindSectionHeader:
      return try configureHeaderView(collectionView, at: indexPath)
    case UICollectionView.elementKindSectionFooter:
      return try configureFooterView(collectionView, at: indexPath)
    default:
      return try configureCustomReusableView(
        collectionView, at: indexPath, of: elementKind
      )
    }
  }
  
  open func configureHeaderView(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath
  ) throws -> UICollectionReusableView? {
    throw ChatError.notImplemented
  }
  
  open func configureFooterView(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath
  ) throws -> UICollectionReusableView? {
    throw ChatError.notImplemented
  }
  
  open func configureCustomReusableView(
    _ collectionView: UICollectionView,
    at indexPath: IndexPath,
    of elementKind: String
  ) throws -> UICollectionReusableView? {
    throw ChatError.notImplemented
  }
  
  // MARK: - Data Source
  
  public var dataSourceSnapshotWillAppply: ((NSDiffableDataSourceSnapshot<String,NSManagedObjectID>) -> (NSDiffableDataSourceSnapshot<String,NSManagedObjectID>))?
  open func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
  ) {
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<String,NSManagedObjectID>
    
    let finalSnapshot = dataSourceSnapshotWillAppply?(snapshot) ?? snapshot
    
    dataSnapshotQueue.async { [dataSource] in
      dataSource?.apply(
        finalSnapshot,
        animatingDifferences: true
      )
    }
  }
  
  open func performFetch() { /* no-op */ }
}
