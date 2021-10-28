//
//  UIKit+Components.swift
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

import PubNubChat
import PubNub

extension UICollectionReusableView {
  public static var reuseIdentifier: String {
    return String(describing: Self.self)
  }
}

extension UICollectionView {
  func register<T: UICollectionReusableView>(cell: T.Type) {
    register(
      T.self,
      forCellWithReuseIdentifier: T.reuseIdentifier
    )
  }
  
  func register<T: UICollectionReusableView>(header: T.Type) {
    register(
      T.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: T.reuseIdentifier
    )
  }
  
  func register<T: UICollectionReusableView>(footer: T.Type) {
    register(
      T.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
      withReuseIdentifier: T.reuseIdentifier
    )
  }
  
  func dequeueOptional<T: CollectionViewCellComponent>(
    _ into: T.Type = T.self,
    for indexPath: IndexPath
  ) -> T? {
    return dequeueReusableCell(
      withReuseIdentifier: T.reuseIdentifier,
      for: indexPath) as? T
  }
  
  func dequeueComponent<T: CollectionViewCellComponent>(
    _ into: T.Type = T.self,
    for indexPath: IndexPath
  ) throws -> T {
    guard let cell: T = dequeueOptional(for: indexPath) else {
      PubNub.log.error("Could not dequeue cell into \(into.reuseIdentifier)")
      throw ChatError.missingRequiredData
    }
    
    return cell
  }
  
  func dequeueHeader<T: ReusableComponentView>(
    _ into: T.Type = T.self, for indexPath: IndexPath
  ) throws -> T {
    guard let header = dequeueReusableSupplementaryView(
      ofKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: T.reuseIdentifier,
      for: indexPath
    ) as? T else {
      PubNub.log.error("Could not dequeue header view into \(into.reuseIdentifier)")
      throw ChatError.missingRequiredData
    }
    
    return header
  }
  
  func dequeueFooter<T: ReusableComponentView>(
    _ into: T.Type = T.self, for indexPath: IndexPath
  ) throws -> T {
    guard let header = dequeueReusableSupplementaryView(
      ofKind: UICollectionView.elementKindSectionFooter,
      withReuseIdentifier: T.reuseIdentifier,
      for: indexPath
    ) as? T else {
      PubNub.log.error("Could not dequeue header view into \(into.reuseIdentifier)")
      throw ChatError.missingRequiredData
    }
    
    return header
  }
  
  func dequeueCustom<T: ReusableComponentView>(
    _ into: T.Type = T.self, ofKind kind: String, for indexPath: IndexPath
  ) throws -> T {
    guard let element = dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: T.reuseIdentifier,
      for: indexPath
    ) as? T else {
      PubNub.log.error("Could not dequeue header view into \(into.reuseIdentifier)")
      throw ChatError.missingRequiredData
    }
    
    return element
  }
}

extension UIApplication {
  var firstWindow: UIWindow? {
    return windows.first(where: \.isKeyWindow)
  }
}

extension UIStackView {
  convenience init(
    frame: CGRect = .zero,
    axis: NSLayoutConstraint.Axis,
    distribution: UIStackView.Distribution,
    alignment: UIStackView.Alignment,
    spacing: CGFloat
  ) {
    self.init(frame: frame)
    
    self.axis = axis
    self.distribution = distribution
    self.alignment = alignment
    self.spacing  = spacing
  }
  
  func removeAllArrangedSubviews() {
    arrangedSubviews.forEach { [weak self] (view) in
      self?.removeArrangedSubview(view)
    }
  }
}

extension UILayoutPriority {
  static let overrideRequire = UILayoutPriority(rawValue: 900.0)
}

extension UIFont {
  func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
    let descriptor = fontDescriptor.withSymbolicTraits(traits)
    return UIFont(descriptor: descriptor!, size: pointSize)
  }
  
  var bold: UIFont {
    withTraits(traits: .traitBold)
  }
  
  var italic: UIFont {
    withTraits(traits: .traitItalic)
  }
}

extension UIColor {
  convenience init(_ hexCode: Int, alpha: CGFloat = 1.0) {
    self.init(
      red: CGFloat((hexCode >> 16) & 0xff),
      green: CGFloat((hexCode >> 8) & 0xff),
      blue: CGFloat(hexCode & 0xff),
      alpha: alpha
    )
  }
}

extension UICollectionViewCell {
  public enum Alignment {
    case leading
    case trailing
    
    func flipped() -> Alignment {
      switch self {
      case .leading:
        return .trailing
      case .trailing:
        return .leading
      }
    }
    
    var stackViewAlignment: UIStackView.Alignment {
      switch self {
      case .leading:
        return .leading
      case .trailing:
        return .trailing
      }
    }
  }
}

extension UIView {
  func priorityFill(axis: NSLayoutConstraint.Axis) -> Self {
    setContentHuggingPriority(.lowest, for: axis)
    return self
  }
}

extension UILayoutPriority {
  static let lowest = UILayoutPriority(defaultLow.rawValue / 2.0)
}

extension CGAffineTransform {
  public init(rotationAngleDegree degree: Double) {
    self.init(rotationAngle: degree * (.pi / 180))
  }
}

extension UIImage {
  func rotate(degree: Double) -> UIImage? {
    var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngleDegree: degree)).size
    // Trim off the extremely small float value to prevent core graphics from rounding it up
    newSize.width = floor(newSize.width)
    newSize.height = floor(newSize.height)
    
    UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    
    // Move origin to middle
    context.translateBy(x: newSize.width/2, y: newSize.height/2)
    // Rotate around middle
    context.rotate(by: CGFloat(degree * (.pi / 180)))
    // Draw the image at its center
    self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
    
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
  }
}
