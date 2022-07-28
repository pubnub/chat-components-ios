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

open class ChatViewController<ModelData, ManagedEntities>: CollectionViewComponent, UIViewControllerTransitioningDelegate
  where ModelData: ChatCustomData,
    ManagedEntities: ChatViewModels,
    ManagedEntities: ManagedChatEntities,
    ManagedEntities.Channel.MemberViewModel == ManagedEntities.Member,
    ManagedEntities.Message.MessageActionModel == ManagedEntities.MessageAction
{
  
  public var cancellables = Set<AnyCancellable>()

  // Message Input Component

  public let messageInputComponent: MessageInputComponent
  private var messageInputComponentBottomConstraint: NSLayoutConstraint?
  
  // A message cell that was long pressed
  
  private weak var gestureRecognizedCell: MessageListItemCell?
  
  // A property that stores preferred emoji picker view size
  
  private var preferredPickerViewSize: CGSize = .zero
  
  private let enableReactions: Bool
  
  public init(
    viewModel: MessageListComponentViewModel<ModelData, ManagedEntities>,
    collectionViewType: UICollectionView.Type,
    collectionViewLayout: UICollectionViewLayout,
    messageInputComponent: MessageInputComponent,
    enableReactions: Bool
  ) {
    
    self.messageInputComponent = messageInputComponent
    self.enableReactions = enableReactions
    
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
  
  open override func onLongPressGestureRecognized(gesture: UIGestureRecognizer) {
    
    if enableReactions && gesture.state == .began {
      
      // Finds the cell that was pressed
      guard let affectedCell = collectionView.visibleCells.first(where: {
        $0.frame.contains(gesture.location(in: collectionView))
      }) as? MessageListItemCell else {
        return
      }
      
      let reactionList = affectedCell.reactionListView.allReactions.map() { $0.reaction }
      let pickerView = AddMessageReactionComponent.DefaultPickerView(reactionList: reactionList)
      
      // Creates and configures a view controller responsible for displaying the emoji picker view
      let viewController = AddMessageReactionComponent(pickerView: pickerView, reactionList: reactionList)
      viewController.modalPresentationStyle = .custom
      viewController.transitioningDelegate = self
      
      // Captures selection from the emoji picker view
      viewController
        .selectedReactionValue
        .sink(receiveValue: { [weak self, weak affectedCell] value in
          self?.onMessageReactionSelected(with: value, for: affectedCell)
      }).store(in: &cancellables)
      
      gestureRecognizedCell = affectedCell
      preferredPickerViewSize = pickerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            
      present(viewController, animated: true)
    }
  }
  
  private func onMessageReactionSelected(
    with value: String,
    for cell: MessageListItemCell?
  ) {
    guard
      let cell = cell,
      let indexPath = collectionView.indexPath(for: cell),
      let viewModel = viewModel as? MessageListComponentViewModel<ModelData, ManagedEntities>
    else {
      return
    }
    
    let message = viewModel.fetchedEntities.object(at: indexPath) as ManagedEntities.Message
    let buttonComponent = cell.reactionListView.allReactions.first(where: { $0.reaction == value} )
    
    if let buttonComponent = buttonComponent {
      viewModel.messageActionTapped?(
        viewModel,
        buttonComponent,
        message,
        nil
      )
    } else {
      preconditionFailure("Not supported yet")
    }
    dismiss(animated: true)
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
  
  // MARK: UIViewControllerTransitioningDelegate
  
  @objc(presentationControllerForPresentedViewController:presentingViewController:sourceViewController:)
  public func presentationController(
    forPresented presented: UIViewController,
    presenting: UIViewController?,
    source: UIViewController
  ) -> UIPresentationController? {
    guard let gestureRecognizedCell = gestureRecognizedCell else {
      return nil
    }
    return AddMessageReaction.PresentationController(
      presentedViewController: presented,
      presentingViewController: presenting,
      messageCell: gestureRecognizedCell,
      messageReactionsComponentSize: preferredPickerViewSize
    )
  }
  
  @objc(animationControllerForPresentedController:presentingController:sourceController:)
  public func animationController(
    forPresented presented: UIViewController,
    presenting: UIViewController,
    source: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    AddMessageReaction.AnimationController(duration: 0.25, isBeingPresented: true)
  }
  
  @objc(animationControllerForDismissedController:)
  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    AddMessageReaction.AnimationController(duration: 0.15, isBeingPresented: false)
  }
}
