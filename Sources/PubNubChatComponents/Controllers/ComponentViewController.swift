//
//  ComponentViewController.swift
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

import PubNubChat
import PubNub

// MARK: Base Components

// Needs to be a UICollectionViewController
open class ComponentViewController: UIViewController {
  
  public var viewModel: CollectionViewComponentViewModel
  
  init(
    viewModel: CollectionViewComponentViewModel
  ) {
    self.viewModel = viewModel
    
    super.init(nibName: nil, bundle: nil)
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    viewModel.viewControllerDidLoad(self)
    viewModel.viewController(self, navigationItem: navigationItem)
  }
  
  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    viewModel.viewController(self, viewWillAppear: animated)
  }
  
  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    viewModel.viewController(self, viewDidAppear: animated)
  }
  
  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    viewModel.viewController(self, viewWillDisappear: animated)
  }
  
  open override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    viewModel.viewController(self, viewDidDisappear: animated)
  }

  @available(*, unavailable, message: "Use init(messageController:) instead")
  required public init?(coder: NSCoder) {
    fatalError("Use init(viewModel:) instead")
  }
  
  @available(*, unavailable, message: "Use init(messageController:) instead")
  override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    fatalError("Use init(viewModel:) instead")
  }
}

open class CollectionViewComponent: ComponentViewController  {
  open var collectionView: UICollectionView
  
  public init(
    viewModel: CollectionViewComponentViewModel,
    collectionViewType: UICollectionView.Type,
    collectionViewLayout: UICollectionViewLayout
  ) {
    self.collectionView = collectionViewType.init(
      frame: .zero,
      collectionViewLayout: collectionViewLayout
    )
    
    super.init(viewModel: viewModel)
  }

  open var configureNavigationItem: ((UINavigationItem) -> Void)?

  override open func viewDidLoad() {
    super.viewDidLoad()
 
    configureConstraints()

    configureNavigationItem?(navigationItem)
  }
  
  open func configureConstraints() {
    view.addSubview(collectionView)

    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.frame = view.bounds
    collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
  }
}
