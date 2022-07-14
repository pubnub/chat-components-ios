//
//  AnimatedTypingIndicatorView.swift
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
import PubNubChat

public class TypingIndicatorCellTheme: CollectionViewCellTheme {
  // Layout

  // Appearance
  @Published public var primaryContentColor: UIColor?
  @Published public var secondaryContentColor: UIColor?
  
  public init(
    cellType: CollectionViewCellComponent.Type = IMessageTypingIndicatorCell.self,
    backgroundColor: UIColor?,
    highlightColor: UIColor? = nil,
    selectedColor: UIColor? = nil,
    primaryContentColor: UIColor?,
    secondaryContentColor: UIColor?
  ) {
    self.primaryContentColor = primaryContentColor
    self.secondaryContentColor = secondaryContentColor

    super.init(
      customType: cellType,
      backgroundColor: backgroundColor,
      highlightColor: highlightColor,
      selectedColor: selectedColor
    )
  }
}

public class AnimatedTypingIndicatorCellTheme: TypingIndicatorCellTheme {
  // Layout

  // Appearance
  public var animationEnabled: Bool = true
  public var pulsing: Bool = true
  public var bounces: Bool = true
  public var bounceDelay: TimeInterval = 0.33
  public var bounceOffset: CGFloat = 0.25
  public var fades: Bool = true
  
  public init(
    cellType: CollectionViewCellComponent.Type = IMessageTypingIndicatorCell.self,
    contentViewType: AnimatingTypingIndicatorView.Type,
    backgroundColor: UIColor? = nil,
    highlightColor: UIColor? = nil,
    selectedColor: UIColor? = nil,
    primaryContentColor: UIColor?,
    secondaryContentColor: UIColor?,
    animationEnabled: Bool,
    pulsing: Bool,
    bounces: Bool,
    bounceDelay: TimeInterval,
    bounceOffset: CGFloat,
    fades: Bool
  ) {
    self.animationEnabled = animationEnabled
    self.pulsing = pulsing
    self.bounces = bounces
    self.bounceDelay = bounceDelay
    self.bounceOffset = bounceOffset
    self.fades = fades
    
    super.init(
      cellType: cellType,
      backgroundColor: backgroundColor,
      highlightColor: highlightColor,
      selectedColor: selectedColor,
      primaryContentColor: primaryContentColor,
      secondaryContentColor: secondaryContentColor
    )
  }
}

public protocol AnimatingTypingIndicatorView: UIView {
  var isAnimating: Bool { get }
  
  func startAnimating(
    with theme: AnimatedTypingIndicatorCellTheme,
    cancelIn store: inout Set<AnyCancellable>
  )
  
  func stopAnimating()
}



/// A subclass of `UICollectionViewCell` used to display the typing indicator.
open class IMessageTypingIndicatorCell: CollectionViewCellComponent {

  open var containerView: IMessageTypingBubbleView = IMessageTypingBubbleView()
  
  open override func prepareForReuse() {
    super.prepareForReuse()
    
    guard let animatingView = contentView as? AnimatingTypingIndicatorView else { return }
    
    if animatingView.isAnimating {
      animatingView.stopAnimating()
    }
  }
  
  // MARK: - Layout
  
  open override func setupSubviews() {
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    contentView.addSubview(containerView)
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    containerView.frame = bounds
  }
  
  open override func configure<Channel: ManagedChannelViewModel>(
    _ channel: Channel,
    typingMemberIds: AnyPublisher<Set<String>, Never>,
    theme: TypingIndicatorCellTheme
  ) {
    containerView.startAnimating(with: theme, cancelIn: &contentCancellables)
  }
}

// MARK: - TypingBubble

/// A subclass of `UIView` that mimics the iMessage typing bubble
open class IMessageTypingBubbleView: UIView, AnimatingTypingIndicatorView {
  
  // MARK:  Properties

  public private(set) var isAnimating: Bool = false
  
  open override var backgroundColor: UIColor? {
    set {
      [contentBubble, cornerBubble, tinyBubble].forEach { $0.backgroundColor = newValue }
    }
    get {
      return contentBubble.backgroundColor
    }
  }
  
  private struct AnimationKeys {
    static let pulse = "typingBubble.pulse"
  }
  
  // MARK: Subviews
  
  /// The indicator used to display the typing animation.
  public let contentBubble = UIView()
  public let animatedDots = AnimatedShapeArrayView()
  public let cornerBubble = CircleShapeView()
  public let tinyBubble = CircleShapeView()
  
  // MARK: Animation Layers
  
  open var contentPulseAnimationLayer: CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = 1
    animation.toValue = 1.04
    animation.duration = 1
    animation.repeatCount = .infinity
    animation.autoreverses = true
    return animation
  }
  
  open var circlePulseAnimationLayer: CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "transform.scale")
    animation.fromValue = 1
    animation.toValue = 1.1
    animation.duration = 0.5
    animation.repeatCount = .infinity
    animation.autoreverses = true
    return animation
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupSubviews()
  }
  
  open func setupSubviews() {
    addSubview(tinyBubble)
    addSubview(cornerBubble)
    addSubview(contentBubble)
    contentBubble.addSubview(animatedDots)
  }
  
  // MARK: Layout
  
  open override func layoutSubviews() {
    super.layoutSubviews()

    // NOTE: To maintain iMessage indicator, width:height ratio of the frame must be close to 1.65
    let ratio = bounds.width / bounds.height
    let extraRightInset = bounds.width - 1.65/ratio * bounds.width
    
    let tinyBubbleRadius: CGFloat = bounds.height / 6
    tinyBubble.frame = CGRect(
      x: 0,
      y: bounds.height - tinyBubbleRadius,
      width: tinyBubbleRadius,
      height: tinyBubbleRadius
    )
    
    let cornerBubbleRadius = tinyBubbleRadius * 2
    let offset: CGFloat = tinyBubbleRadius / 6
    cornerBubble.frame = CGRect(
      x: tinyBubbleRadius - offset,
      y: bounds.height - (1.5 * cornerBubbleRadius) + offset,
      width: cornerBubbleRadius,
      height: cornerBubbleRadius
    )
    
    let contentBubbleFrame = CGRect(
      x: tinyBubbleRadius + offset,
      y: 0,
      width: bounds.width - (tinyBubbleRadius + offset) - extraRightInset,
      height: bounds.height - (tinyBubbleRadius + offset)
    )
    let contentBubbleFrameCornerRadius = contentBubbleFrame.height / 2
    
    contentBubble.frame = contentBubbleFrame
    contentBubble.layer.cornerRadius = contentBubbleFrameCornerRadius
    
    let insets = UIEdgeInsets(
      top: offset,
      left: contentBubbleFrameCornerRadius / 1.25,
      bottom: offset,
      right: contentBubbleFrameCornerRadius / 1.25
    )
    animatedDots.frame = contentBubble.bounds.inset(by: insets)
  }
  
  // MARK: Animation API
  
  open func startAnimating(
    with theme: TypingIndicatorCellTheme,
    cancelIn store: inout Set<AnyCancellable>
  ) {
    if let animatingTheme = theme as? AnimatedTypingIndicatorCellTheme {
      startAnimating(with: animatingTheme, cancelIn: &store)
    }
    
    theme.$primaryContentColor.sink { [weak self] primaryColor in
      self?.backgroundColor = primaryColor
    }.store(in: &store)
    theme.$primaryContentColor.sink { [weak self] secondaryColor in
      self?.animatedDots.dotColor = secondaryColor
    }.store(in: &store)
  }
  
  open func startAnimating(
    with theme: AnimatedTypingIndicatorCellTheme,
    cancelIn store: inout Set<AnyCancellable>
  ) {
    if theme.animationEnabled {
      startAnimating(
        pulse: theme.pulsing,
        bounces: theme.bounces,
        bounceDelay: theme.bounceDelay,
        bounceOffset: theme.bounceOffset,
        fades: theme.fades
      )
    } else {
      stopAnimating()
    }
  }
  
  open func startAnimating(
    pulse: Bool,
    bounces: Bool = true,
    bounceDelay: TimeInterval = 0.33,
    bounceOffset: CGFloat = 0.25,
    fades: Bool = true
  ) {
    defer { isAnimating = true }
    guard !isAnimating else { return }
    animatedDots.startAnimating(
      bounce: bounces, bounceDelay: bounceDelay, bounceOffset: bounceOffset, fade: fades
    )
    if pulse {
      contentBubble.layer.add(contentPulseAnimationLayer, forKey: AnimationKeys.pulse)
      [cornerBubble, tinyBubble].forEach { $0.layer.add(circlePulseAnimationLayer, forKey: AnimationKeys.pulse) }
    }
  }

  open func stopAnimating() {
    defer { isAnimating = false }
    guard isAnimating else { return }
    animatedDots.stopAnimating()
    [contentBubble, cornerBubble, tinyBubble].forEach { $0.layer.removeAnimation(forKey: AnimationKeys.pulse) }
  }
}


// MARK: - TypingIndicator

open class AnimatedShapeArrayView: UIView {

  // MARK: Properties
  
  /// A convenience accessor for the `backgroundColor` of each dot
  open var dotColor: UIColor? {
    didSet {
      dots.forEach { $0.backgroundColor = dotColor }
    }
  }

  /// A flag indicating the animation state
  public private(set) var isAnimating: Bool = false
  
  /// Keys for each animation layer
  private struct AnimationKeys {
    static let offset = "typingIndicator.offset"
    static let bounce = "typingIndicator.bounce"
    static let opacity = "typingIndicator.opacity"
  }
  
  open func initialOffsetAnimationLayer(bounceOffset: CGFloat) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "transform.translation.y")
    animation.byValue = -bounceOffset
    animation.duration = 0.5
    animation.isRemovedOnCompletion = true
    return animation
  }

  open func bounceAnimationLayer(bounceOffset: CGFloat, timeOffset: TimeInterval) -> CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "transform.translation.y")
    animation.toValue = -bounceOffset
    animation.fromValue = bounceOffset
    animation.duration = 0.5
    animation.repeatCount = .infinity
    animation.autoreverses = true
    animation.timeOffset = timeOffset
    return animation
  }
  
  /// The `CABasicAnimation` applied when `isFadeEnabled` is TRUE
  open var opacityAnimationLayer: CABasicAnimation {
    let animation = CABasicAnimation(keyPath: "opacity")
    animation.fromValue = 1
    animation.toValue = 0.5
    animation.duration = 0.5
    animation.repeatCount = .infinity
    animation.autoreverses = true
    return animation
  }
  
  // MARK: - Subviews
  
  public let stackView = UIStackView()
  
  public let dots: [CircleShapeView] = {
    return [CircleShapeView(), CircleShapeView(), CircleShapeView()]
  }()
  
  // MARK: - Initialization
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupView()
  }
  
  /// Sets up the view
  private func setupView() {
    dots.forEach {
      $0.backgroundColor = dotColor
      $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
      stackView.addArrangedSubview($0)
    }
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fillEqually
    addSubview(stackView)
  }
  
  // MARK: - Layout
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    stackView.frame = bounds
    stackView.spacing = bounds.width > 0 ? 5 : 0
  }
  
  // MARK: - Animation API
  
  open func didChangeAnimation(
    _ animate: Bool,
    bounces: Bool = true,
    bounceDelay: TimeInterval,
    bounceOffset: CGFloat,
    fades: Bool = true
  ) {
    if animate {
      startAnimating(bounce: bounces, bounceDelay: bounceDelay, bounceOffset: bounceOffset, fade: fades)
    } else {
      stopAnimating()
    }
  }
  
  /// Sets the state of the `TypingIndicator` to animating and applies animation layers
  open func startAnimating(bounce: Bool, bounceDelay: TimeInterval, bounceOffset: CGFloat, fade: Bool) {
    defer { isAnimating = true }
    guard !isAnimating else { return }
    var delay: TimeInterval = 0
    for dot in dots {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
        guard let self = self else { return }
        if bounce {
          dot.layer.add([
            AnimationKeys.offset: self.initialOffsetAnimationLayer(bounceOffset: bounceOffset),
            AnimationKeys.bounce: self.bounceAnimationLayer(bounceOffset: bounceOffset, timeOffset: delay + bounceDelay)
          ])
        }
        if fade {
          dot.layer.add(self.opacityAnimationLayer, forKey: AnimationKeys.opacity)
        }
      }
      delay += bounceDelay
    }
  }
  
  /// Sets the state of the `TypingIndicator` to not animating and removes animation layers
  open func stopAnimating() {
    defer { isAnimating = false }
    guard isAnimating else { return }
    dots.forEach {
      $0.layer.removeAnimation(forKey: AnimationKeys.bounce)
      $0.layer.removeAnimation(forKey: AnimationKeys.opacity)
    }
  }
}

// MARK: - BubbleCircle

/// A `UIView` subclass that maintains a mask to keep it fully circular
open class CircleShapeView: UIView {
  
  /// Lays out subviews and applys a circular mask to the layer
  open override func layoutSubviews() {
    super.layoutSubviews()
    layer.mask = roundedMask(corners: .allCorners, radius: bounds.height / 2)
  }
  
  /// Returns a rounded mask of the view
  ///
  /// - Parameters:
  ///   - corners: The corners to round
  ///   - radius: The radius of curve
  /// - Returns: A mask
  open func roundedMask(corners: UIRectCorner, radius: CGFloat) -> CAShapeLayer {
    let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    let mask = CAShapeLayer()
    mask.path = path.cgPath
    return mask
  }
}

extension CALayer {
  func add(_ animations: [String: CAAnimation]) {
    animations.forEach { add($1, forKey: $0) }
  }
}
