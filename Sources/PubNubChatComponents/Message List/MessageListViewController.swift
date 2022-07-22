//
//  MessageListViewController.swift
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
import CoreData
import Combine
import LinkPresentation

import ChatLayout
import InputBarAccessoryView

import PubNub
import PubNubChat

open class ChatViewController: CollectionViewComponent {
  
  // Message Input Component

  public let messageInputComponent: MessageInputComponent
  private var messageInputComponentBottomConstraint: NSLayoutConstraint?
  
  public init(
    viewModel: CollectionViewComponentViewModel,
    collectionViewType: UICollectionView.Type,
    collectionViewLayout: UICollectionViewLayout,
    messageInputComponent: MessageInputComponent
  ) {
    
    self.messageInputComponent = messageInputComponent
    
    super.init(
      viewModel: viewModel,
      collectionViewType: collectionViewType,
      collectionViewLayout: collectionViewLayout
    )
  }
  
  // MARK: - Open Methods

  open func transition(
    layout: UICollectionViewLayout,
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    guard let chatLayout = layout as? CollectionViewChatLayout else { return }
    
    let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.setNeedsLayout()
    coordinator.animate(alongsideTransition: { _ in
      self.collectionView.collectionViewLayout.invalidateLayout()
    }, completion: { _ in
      if let positionSnapshot = positionSnapshot,
         !self.isUserInitiatedScrolling {
        chatLayout.restoreContentOffset(with: positionSnapshot)
      }
      self.collectionView.collectionViewLayout.invalidateLayout()
    })
  }
  
  // MARK: - View Lifecycle

  open override func configureConstraints() {
    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

    view.addSubview(messageInputComponent)
    messageInputComponent.translatesAutoresizingMaskIntoConstraints = false

    messageInputComponent.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
    messageInputComponent.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    messageInputComponent.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    messageInputComponentBottomConstraint = messageInputComponent.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    messageInputComponentBottomConstraint?.isActive = true
    
    messageInputComponent.bind(self.view, scrollView: self.collectionView, bottomInset: messageInputComponentBottomConstraint)
  }
  
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  
    self.messageInputComponent.canBecomeFirstResponder = true
  }
  
  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    self.messageInputComponent.inputTextView?.resignFirstResponder()
    self.messageInputComponent.canBecomeFirstResponder = false
  }
  
  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    guard isViewLoaded else { return }
    
    transition(
      layout: collectionView.collectionViewLayout,
      to: size,
      with: coordinator
    )

    super.viewWillTransition(to: size, with: coordinator)
  }

  // MARK: UIScrollViewDelegate
  
  fileprivate var isUserInitiatedScrolling: Bool {
    return collectionView.isDragging || collectionView.isDecelerating
  }
}
