//
//  AddMessageReactionAnimation.swift
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

internal enum AddMessageReaction {
  
  // MARK: Custom presentation controller (UIPresentationController)

  @objc
  class PresentationController: UIPresentationController {
    private let messageCell: MessageListItemCell
    private let messageReactionsComponentSize: CGSize
    
    private lazy var dimmingView: UIView = {
      let view = UIView()
      
      view.frame = containerView?.bounds ?? .zero
      view.backgroundColor = .clear
      view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapGestureRecognized(_:))))
      
      return view
    }()
    
    init(
      presentedViewController: UIViewController,
      presentingViewController: UIViewController?,
      messageCell: MessageListItemCell,
      messageReactionsComponentSize: CGSize
    ) {
      self.messageCell = messageCell
      self.messageReactionsComponentSize = messageReactionsComponentSize
      
      super.init(
        presentedViewController: presentedViewController,
        presenting: presentingViewController
      )
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
      
      guard let containerView = containerView else {
        return super.frameOfPresentedViewInContainerView
      }
      
      let messageCellFrame = messageCell.superview?.convert(messageCell.frame, to: containerView) ?? .zero
      
      // Presents the reaction components beyond the cell that was pressed.
      // If it doesn't fit at the screen, then the picker component is presented at the bottom of a view in which a presentation occurs
      let x = messageCellFrame.minX
      let y = min(containerView.frame.maxY - messageReactionsComponentSize.height - containerView.safeAreaInsets.bottom, messageCellFrame.maxY + 10)
      
      return CGRect(
        x: x,
        y: y,
        width: messageReactionsComponentSize.width,
        height: messageReactionsComponentSize.height
      )
    }
    
    @objc
    func onTapGestureRecognized(_ sender: UIGestureRecognizer) {
      presentedViewController.dismiss(animated: true)
    }
    
    override func presentationTransitionWillBegin() {
      guard let containerView = containerView else {
        return
      }
      containerView.addSubview(dimmingView)
      containerView.sendSubviewToBack(dimmingView)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
      if completed {
        dimmingView.removeFromSuperview()
      }
    }
  }
  
  // MARK: UIViewControllerAnimatedTransitioning aka animation controller
  
  @objc
  class AnimationController : NSObject, UIViewControllerAnimatedTransitioning {
    
    private let duration: TimeInterval
    private let isBeingPresented: Bool
    
    init(duration: TimeInterval, isBeingPresented: Bool) {
      self.duration = duration
      self.isBeingPresented = isBeingPresented
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
      duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
      guard
        let currentViewController = transitionContext.viewController(forKey: .from),
        let finalViewController = transitionContext.viewController(forKey: .to)
      else {
        transitionContext.completeTransition(false)
        return
      }
      
      let finalFrame = transitionContext.finalFrame(for: finalViewController)
      let propertyAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
      
      if isBeingPresented {
        
        finalViewController.view.frame = CGRect(x: finalFrame.minX + 0.5 * finalFrame.width, y: finalFrame.minY, width: 0, height: 0)
        finalViewController.view.alpha = 0
        transitionContext.containerView.addSubview(finalViewController.view)
        
        propertyAnimator.addAnimations {
          finalViewController.view.frame = finalFrame
          finalViewController.view.alpha = 1
        }
        propertyAnimator.addCompletion() { _ in
          transitionContext.completeTransition(true)
        }
      } else {
        
        propertyAnimator.addAnimations {
          currentViewController.view.alpha = 0
        }
        propertyAnimator.addCompletion() { _ in
          currentViewController.view.removeFromSuperview()
          transitionContext.completeTransition(true)
        }
      }
      
      propertyAnimator.startAnimation()
    }
  }
}
