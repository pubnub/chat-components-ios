//
//  BubbleView.swift
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

import ChatLayout

import PubNubChat

// MARK: Bezier View

public enum BubbleContainerType {
  case none
  case normal
  case tailed
  
  var offset: CGFloat {
    switch self {
    case .none:
      return 0
    case .normal:
      return 2
    case .tailed:
      return 6
    }
  }
}

open class BubbleContainerView: UIView {

  lazy open var messageTextContent = PubNubMessageContentTextView(frame: bounds)
  
  override init(frame: CGRect) {
    super.init(frame: frame)

    setupSubviews()
  }

  required public init?(coder: NSCoder) {
    super.init(coder: coder)

    setupSubviews()
  }

  open func setupSubviews() {
    layoutMargins = .zero
    translatesAutoresizingMaskIntoConstraints = false
    insetsLayoutMarginsFromSafeArea = false

    addSubview(messageTextContent)
    messageTextContent.translatesAutoresizingMaskIntoConstraints = false
    
    messageTextContent.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    messageTextContent.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
    messageTextContent.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    messageTextContent.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
  }
}

// MARK: - Drawing Bubbles

extension BubbleContainerView {
  public static func generateLeadingTailedBezierPath(offset: CGFloat, size: CGSize) -> UIBezierPath {
    let size = CGSize(width: size.width - offset, height: size.height)
    let bezierPath = UIBezierPath()
    bezierPath.move(to: CGPoint(x: 22, y: size.height))
    bezierPath.addLine(to: CGPoint(x: size.width - 17, y: size.height))
    bezierPath.addCurve(
      to: CGPoint(x: size.width, y: size.height - 17),
      controlPoint1: CGPoint(x: size.width - 7.61, y: size.height),
      controlPoint2: CGPoint(x: size.width, y: size.height - 7.61)
    )
    bezierPath.addLine(to: CGPoint(x: size.width, y: 17))
    bezierPath.addCurve(
      to: CGPoint(x: size.width - 17, y: 0),
      controlPoint1: CGPoint(x: size.width, y: 7.61),
      controlPoint2: CGPoint(x: size.width - 7.61, y: 0)
    )
    bezierPath.addLine(to: CGPoint(x: 21, y: 0))
    bezierPath.addCurve(
      to: CGPoint(x: 4, y: 17),
      controlPoint1: CGPoint(x: 11.61, y: 0),
      controlPoint2: CGPoint(x: 4, y: 7.61)
    )
    bezierPath.addLine(to: CGPoint(x: 4, y: size.height - 11))
    bezierPath.addCurve(
      to: CGPoint(x: 0, y: size.height),
      controlPoint1: CGPoint(x: 4, y: size.height - 1),
      controlPoint2: CGPoint(x: 0, y: size.height)
    )
    bezierPath.addLine(to: CGPoint(x: -0.05, y: size.height - 0.01))
    bezierPath.addCurve(
      to: CGPoint(x: 11.04, y: size.height - 4.04),
      controlPoint1: CGPoint(x: 4.07, y: size.height + 0.43),
      controlPoint2: CGPoint(x: 8.16, y: size.height - 1.06)
    )
    bezierPath.addCurve(
      to: CGPoint(x: 22, y: size.height),
      controlPoint1: CGPoint(x: 16, y: size.height),
      controlPoint2: CGPoint(x: 19, y: size.height)
    )
    bezierPath.close()
    bezierPath.apply(CGAffineTransform(translationX: offset, y: 0))
    
    return bezierPath
  }
  
  public static func generateTrailingTailedBezierPath(offset: CGFloat, size: CGSize) -> UIBezierPath {
    let bezierPath = generateLeadingTailedBezierPath(offset: offset, size: size)
    bezierPath.apply(CGAffineTransform(scaleX: -1, y: 1))
    bezierPath.apply(CGAffineTransform(translationX: size.width, y: 0))
    return bezierPath
  }
  
  public static func generateLeadingNormalBezierPath(offset: CGFloat, size: CGSize) -> UIBezierPath {
    let bezierPath = UIBezierPath(
      roundedRect: CGRect(x: offset, y: 0, width: size.width - offset, height: size.height),
      cornerRadius: 17
    )
    return bezierPath
  }
  
  public static func generateTrailingNormalBezierPath(offset: CGFloat, size: CGSize) -> UIBezierPath {
    let bezierPath = generateLeadingNormalBezierPath(offset: offset, size: size)
    bezierPath.apply(CGAffineTransform(scaleX: -1, y: 1))
    bezierPath.apply(CGAffineTransform(translationX: size.width, y: 0))
    return bezierPath
  }
}
