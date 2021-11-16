//
//  ThemeProvider.swift
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

import ChatLayout

open class ComponentThemeProvider {
  public static var shared = ComponentThemeProvider()
  private init() {}
  
  @Published public var template: ThemeTemplate = .init()
}

// MARK: - Chat Provider Ext

extension ChatProvider {
  public var themeProvider: ComponentThemeProvider {
    return ComponentThemeProvider.shared
  }
}

// MARK: - Theme Template

public class ThemeTemplate: ObservableObject {
  @Published public var channelListComponent: ChannelListComponentTheme
  @Published public var memberListComponent: MemberListComponentTheme
  @Published public var messageListComponent: MessageListComponentTheme
  @Published public var messageInputComponent: MessageInputComponentTheme
  
  public init(
    channelListComponent: ChannelListComponentTheme = .pubnubDefaultGroupChannelList,
    memberListComponent: MemberListComponentTheme = .pubnubDefaultGroupMemberList,
    messageListComponent: MessageListComponentTheme = .pubnubGroupChat,
    messageInputComponent: MessageInputComponentTheme = .pubnubGroupChat
  ) {
    self.channelListComponent = channelListComponent
    self.memberListComponent = memberListComponent
    self.messageListComponent = messageListComponent
    self.messageInputComponent = messageInputComponent
  }
}

// MARK: - UIKit View Themes

public class ViewControllerComponentTheme: ObservableObject {
  // Layout
  public var controllerType: ComponentViewController.Type
  // Theme
  @Published public var backgroundColor: UIColor?
  @Published public var navigationBar: NavigationBarTheme
  
  public init(
    controllerType: ComponentViewController.Type,
    backgroundColor: UIColor?,
    navigationBar: NavigationBarTheme
  ) {
    self.controllerType = controllerType
    self.backgroundColor = backgroundColor
    self.navigationBar = navigationBar
  }
}

extension UIViewController {
  func theming<T: ViewControllerComponentTheme>(_ theme: T, cancelIn store: inout Set<AnyCancellable>) {
    theme.$backgroundColor.assign(to: \.backgroundColor, on: view).store(in: &store)
  }
}

// MARK: - CollectionView

public class CollectionViewComponentTheme: ObservableObject {
  public var viewType: UICollectionView.Type
  public var layoutType: CollectionViewLayoutComponent.Type
  public var headerType: ReusableComponentView.Type
  public var footerType: ReusableComponentView.Type
  
  @Published public var backgroundColor: UIColor?
  @Published public var scrollViewTheme: ScrollViewComponentTheme
  @Published public var refreshControlTheme: RefreshControlTheme?
  @Published public var prefetchIndexThreshold: Int?
  @Published public var isPrefetchingEnabled: Bool

  public init(
    viewType: UICollectionView.Type = UICollectionView.self,
    layoutType: CollectionViewLayoutComponent.Type,
    headerType: ReusableComponentView.Type,
    footerType: ReusableComponentView.Type,
    backgroundColor: UIColor?,
    scrollViewTheme: ScrollViewComponentTheme,
    refreshControlTheme: RefreshControlTheme?,
    prefetchIndexThreshold: Int?,
    isPrefetchingEnabled: Bool
  ) {
    self.viewType = viewType
    self.layoutType = layoutType
    self.headerType = headerType
    self.footerType = footerType
    self.backgroundColor = backgroundColor
    self.refreshControlTheme = refreshControlTheme
    self.prefetchIndexThreshold = prefetchIndexThreshold
    self.scrollViewTheme = scrollViewTheme
    self.isPrefetchingEnabled = isPrefetchingEnabled
  }
}

extension UICollectionView {
  func theming(
    _ theme: CollectionViewComponentTheme,
    cancelIn store: inout Set<AnyCancellable>
  ) {
    theme.$isPrefetchingEnabled.weakAssign(to: \.isPrefetchingEnabled, on: self).store(in: &store)
    theme.$backgroundColor.weakAssign(to: \.backgroundColor, on: self).store(in: &store)
    
    var localStore = Set<AnyCancellable>()
    
    theme.$scrollViewTheme.sink { [weak self] scrollTheme in
      self?.theming(scrollTheme, cancelIn: &localStore)
    }.store(in: &store)
    
    theme.$refreshControlTheme.sink { [weak self] refreshTheme in
      if let refreshTheme = refreshTheme {
        if self?.refreshControl == nil {
          self?.refreshControl = refreshTheme.viewType.init()
        }
        
        self?.refreshControl?.theming(refreshTheme, cancelIn: &localStore)
      } else {
        self?.refreshControl = nil
      }
    }.store(in: &store)
    
    store.formUnion(localStore)
  }
}

// MARK: - UINavigationBar

public class NavigationBarTheme: ObservableObject {
  @Published public var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode
  @Published public var standardAppearance: UINavigationBarAppearance?
  @Published public var compactAppearance: UINavigationBarAppearance?
  @Published public var scrollEdgeAppearance: UINavigationBarAppearance?
  
  @Published public var customTitleView: BasicComponentTheme
  
  @Published public var barButtonThemes: [String: BarButtonItemTheme]
  
  public init(
    largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode,
    standardAppearance: UINavigationBarAppearance?,
    compactAppearance: UINavigationBarAppearance?,
    scrollEdgeAppearance: UINavigationBarAppearance?,
    customTitleView: BasicComponentTheme,
    barButtonThemes: [String: BarButtonItemTheme]
  ) {
    self.largeTitleDisplayMode = largeTitleDisplayMode
    self.standardAppearance = standardAppearance
    self.compactAppearance = compactAppearance
    self.scrollEdgeAppearance = scrollEdgeAppearance
    self.customTitleView = customTitleView
    self.barButtonThemes = barButtonThemes
  }
}

extension UINavigationItem {
  func theming(_ theme: NavigationBarTheme, cancelIn store: inout Set<AnyCancellable>) {
    theme.$largeTitleDisplayMode.weakAssign(to: \.largeTitleDisplayMode, on: self).store(in: &store)
    theme.$standardAppearance.weakAssign(to: \.standardAppearance, on: self).store(in: &store)
    theme.$compactAppearance.weakAssign(to: \.compactAppearance, on: self).store(in: &store)
    theme.$scrollEdgeAppearance.weakAssign(to: \.scrollEdgeAppearance, on: self).store(in: &store)
  }
}

public class BarButtonItemTheme: ButtonComponentTheme {
  public var viewType: BarButtonItemComponent.Type
  
  @Published public var buttonItemAppearance: UIBarButtonItemAppearance
  
  public init(
    viewType: BarButtonItemComponent.Type,
    buttonTheme: ButtonComponentTheme,
    buttonItemAppearance: UIBarButtonItemAppearance
  ) {
    self.viewType = viewType
    self.buttonItemAppearance = buttonItemAppearance
    
    super.init(
      backgroundColor: buttonTheme.backgroundColor,
      buttonType: buttonTheme.buttonType,
      tintColor: buttonTheme.tintColor,
      title: buttonTheme.title,
      titleHighlighted: buttonTheme.titleHighlighted,
      titleFont: buttonTheme.titleFont,
      image: buttonTheme.image,
      imageHighlighted: buttonTheme.imageHighlighted
    )
  }
}

// MARK: - RefreshControlTheme

public class RefreshControlTheme: ObservableObject {
  public var viewType: UIRefreshControl.Type
  
  @Published public var pullToRefreshTitle: NSAttributedString?
  @Published public var pullToRefreshTintColor: UIColor?
  
  public init(
    viewType: UIRefreshControl.Type = UIRefreshControl.self,
    pullToRefreshTitle: NSAttributedString?,
    pullToRefreshTintColor: UIColor?
  ) {
    self.viewType = viewType
    self.pullToRefreshTitle = pullToRefreshTitle
    self.pullToRefreshTintColor = pullToRefreshTintColor
  }
}

extension UIRefreshControl {
  func theming(
    _ theme: RefreshControlTheme,
    cancelIn store: inout Set<AnyCancellable>
  ) {
    theme.$pullToRefreshTitle.weakAssign(to: \.attributedTitle, on: self).store(in: &store)
    theme.$pullToRefreshTintColor.weakAssign(to: \.tintColor, on: self).store(in: &store)
  }
}

// MARK: - CollectionViewCell

public class CollectionViewCellTheme: ObservableObject {
  public var cellType: CollectionViewCellComponent.Type
  @Published public var backgroundColor: UIColor?
  @Published public var highlightColor: UIColor?
  @Published public var selectedColor: UIColor?

  public init(
    customType: CollectionViewCellComponent.Type = CollectionViewCellComponent.self,
    backgroundColor: UIColor?,
    highlightColor: UIColor?,
    selectedColor: UIColor?
  ) {
    self.cellType = customType
    self.backgroundColor = backgroundColor
    self.highlightColor = highlightColor
    self.selectedColor = selectedColor
  }
}

extension CollectionViewCellComponent {
  public func theming<T: CollectionViewCellTheme>(_ theme: T) {
    theme.$selectedColor
      .combineLatest(
        theme.$backgroundColor,
        theme.$highlightColor,
        publisher(for: \.isSelected).combineLatest(
          publisher(for: \.isHighlighted)
        )
      )
      .sink { [weak self] selectedColor, backgroundColor, highlightedColor, cellStatus in
        switch (cellStatus.0, cellStatus.1) {
        case (_, true):
          self?.backgroundColor = highlightedColor
        case (true, false):
          self?.backgroundColor = selectedColor
        case (false, false):
          self?.backgroundColor = backgroundColor
        }
      }
      .store(in: &cancellables)
  }
}

// MARK: - Image

public class ImageComponentTheme: ObservableObject {
  public var customType: ImageComponentView.Type

  @Published public var localImage: UIImage?
  @Published public var cornerRadius: CGFloat?
  @Published public var margin: UIEdgeInsets
  
  public init(
    customType: ImageComponentView.Type = PubNubAvatarComponentView.self,
    localImage: UIImage? = nil,
    cornerRadius: CGFloat,
    margin: UIEdgeInsets = .zero
  ) {
    self.customType = customType
    self.cornerRadius = cornerRadius
    self.margin = margin
    self.localImage = localImage
  }
  
  public static var empty: ImageComponentTheme {
    return ImageComponentTheme(
      customType: PubNubAvatarComponentView.self,
      localImage: nil,
      cornerRadius: .zero,
      margin: .zero
    )
  }
}

extension ImageComponentView {
  
  public func theming(
    _ theme: ImageComponentTheme,
    cancelIn store: inout Set<AnyCancellable>
  ) {
    theme.$cornerRadius.sink { [weak self] radius in
      self?.setCorner(radius: radius)
    }.store(in: &store)
    
    theme.$margin.weakAssign(to: \.layoutMargins, on: self)
    .store(in: &store)
  }
}

// MARK: - Label

open class LabelComponentTheme: ObservableObject {
  // Layout
  public var customType: LabelComponentView.Type
  // Appearance
  @Published public var textFont: UIFont?
  @Published public var textColor: UIColor?
  @Published public var textAlignment: NSTextAlignment
  @Published public var adjustsFontForContentSizeCategory: Bool
  @Published public var textMargin: UIEdgeInsets
  
  public init(
    customType: LabelComponentView.Type,
    textFont: UIFont?,
    textColor: UIColor?,
    adjustsFontForContentSizeCategory: Bool,
    textAlignment: NSTextAlignment,
    textMargin: UIEdgeInsets
  ) {
    self.customType = customType
    self.textFont = textFont
    self.textColor = textColor
    self.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory
    self.textAlignment = textAlignment
    self.textMargin = textMargin
  }
  
  public static var empty: LabelComponentTheme {
    return LabelComponentTheme(
      customType: PubNubLabelComponentView.self,
      textFont: nil,
      textColor: nil,
      adjustsFontForContentSizeCategory: true,
      textAlignment: .natural,
      textMargin: .zero
    )
  }
}

extension LabelComponentView {
  
  public func theming(
    _ theme: LabelComponentTheme,
    cancelIn store: inout Set<AnyCancellable>
  ) {
    theme.$textColor.weakAssign(to: \.textColor, on: self).store(in: &store)
    theme.$textFont.weakAssign(to: \.font, on: self).store(in: &store)
    theme.$textAlignment.weakAssign(to: \.textAlignment, on: self).store(in: &store)
    theme.$adjustsFontForContentSizeCategory
      .weakAssign(to: \.adjustsFontForContentSizeCategory, on: self).store(in: &store)

    theme.$textMargin.weakAssign(to: \.layoutMargins, on: self).store(in: &store)
  }
}

// MARK: - BubbleView

public class BubbleComponentTheme: ObservableObject {
  @Published public var alignment: UICollectionViewCell.Alignment
  @Published public var containerType: BubbleContainerType
  @Published public var backgroundColor: UIColor?
  @Published public var tailSize: CGFloat
  @Published public var layoutMargin: UIEdgeInsets
  
  public init(
    alignment: UICollectionViewCell.Alignment = .leading,
    containerType: BubbleContainerType = .tailed,
    backgroundColor: UIColor = .systemBlue,
    tailSize: CGFloat = 5,
    layoutMargin: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
  ) {
    self.alignment = alignment
    self.containerType = containerType
    self.backgroundColor = backgroundColor
    self.tailSize = tailSize
    self.layoutMargin = layoutMargin
  }
}

extension BubbleContainerView {

  func theming(_ theme: BubbleComponentTheme, cancelIn store: inout Set<AnyCancellable>) {

    theme.$backgroundColor.weakAssign(to: \.backgroundColor, on: self).store(in: &store)
    theme.$layoutMargin.weakAssign(to: \.layoutMargins, on: self).store(in: &store)

    theme.$alignment.combineLatest(theme.$containerType, publisher(for: \.bounds))
      .sink { [weak self] alignment, bubbleType, viewBounds in

        let maskLayer = CAShapeLayer()
        maskLayer.frame = viewBounds
        
        let bezierPath: UIBezierPath
        switch (bubbleType, alignment) {
        case (.none, _):
          bezierPath = .init(rect: .zero)
        case (.normal, .leading):
          bezierPath = BubbleContainerView.generateLeadingNormalBezierPath(
            offset: bubbleType.offset, size: viewBounds.size
          )
        case (.normal, .trailing):
          bezierPath = BubbleContainerView.generateTrailingNormalBezierPath(
            offset: bubbleType.offset, size: viewBounds.size
          )
        case (.tailed, .leading):
          bezierPath = BubbleContainerView.generateLeadingTailedBezierPath(
            offset: bubbleType.offset, size: viewBounds.size
          )
        case (.tailed, .trailing):
          bezierPath = BubbleContainerView.generateTrailingTailedBezierPath(
            offset: bubbleType.offset, size: viewBounds.size
          )
        }
        
        maskLayer.path = bezierPath.cgPath
        self?.layer.mask = maskLayer
      }
      .store(in: &store)
    
    theme.$alignment.combineLatest(theme.$containerType, theme.$tailSize)
      .sink { [weak self] alignment, containerType, tailSize in
        guard let strongSelf = self else { return }

        
        var edgeInsets = UIEdgeInsets(
          top: strongSelf.layoutMargins.top,
          left: strongSelf.layoutMargins.left,
          bottom: strongSelf.layoutMargins.bottom,
          right: strongSelf.layoutMargins.right
        )
        
        edgeInsets.left -= alignment == .leading ? -tailSize : tailSize
        edgeInsets.right += alignment == .leading ? -tailSize : tailSize
        
        self?.layoutMargins = edgeInsets
      }
      .store(in: &store)
  }
}

// MARK: - TextView

public class ScrollViewComponentTheme: ObservableObject {
  @Published public var isScrollEnabled: Bool = false
  @Published public var showsHorizontalScrollIndicator: Bool = false
  @Published public var showsVerticalScrollIndicator: Bool = false
  @Published public var bounces: Bool = false
  @Published public var bouncesZoom: Bool = false
  @Published public var scrollsToTop: Bool = false
  @Published public var automaticallyAdjustsScrollIndicatorInsets: Bool = true
  @Published public var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior
  @Published public var keyboardDismissMode: UIScrollView.KeyboardDismissMode

  
  public init(
    isScrollEnabled: Bool = false,
    showsHorizontalScrollIndicator: Bool = false,
    showsVerticalScrollIndicator: Bool = false,
    bounces: Bool = false,
    bouncesZoom: Bool = false,
    scrollsToTop: Bool = false,
    automaticallyAdjustsScrollIndicatorInsets: Bool = true,
    contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic,
    keyboardDismissMode: UIScrollView.KeyboardDismissMode = .interactive
  ) {
    self.isScrollEnabled = isScrollEnabled
    self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
    self.showsVerticalScrollIndicator = showsVerticalScrollIndicator
    self.bounces = bounces
    self.bouncesZoom = bouncesZoom
    self.scrollsToTop = scrollsToTop
    self.automaticallyAdjustsScrollIndicatorInsets = automaticallyAdjustsScrollIndicatorInsets
    self.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
    self.keyboardDismissMode = keyboardDismissMode
  }
  
  public static var disabled: ScrollViewComponentTheme {
    return ScrollViewComponentTheme(
      isScrollEnabled: false,
      showsHorizontalScrollIndicator: false,
      showsVerticalScrollIndicator: false,
      bounces: false,
      bouncesZoom: false,
      scrollsToTop: false,
      automaticallyAdjustsScrollIndicatorInsets: false,
      contentInsetAdjustmentBehavior: .never,
      keyboardDismissMode: .interactive
    )
  }
  
  public static var enabled: ScrollViewComponentTheme {
    return ScrollViewComponentTheme(
      isScrollEnabled: true,
      showsHorizontalScrollIndicator: true,
      showsVerticalScrollIndicator: true,
      bounces: true,
      bouncesZoom: true,
      scrollsToTop: true,
      automaticallyAdjustsScrollIndicatorInsets: true,
      contentInsetAdjustmentBehavior: .automatic,
      keyboardDismissMode: .interactive
    )
  }
}

extension UIScrollView {
  public func theming(_ theme: ScrollViewComponentTheme, cancelIn store: inout Set<AnyCancellable>) {
    theme.$isScrollEnabled.weakAssign(to: \.isScrollEnabled, on: self).store(in: &store)
    theme.$showsHorizontalScrollIndicator.weakAssign(to: \.showsHorizontalScrollIndicator, on: self).store(in: &store)
    theme.$showsVerticalScrollIndicator.weakAssign(to: \.showsVerticalScrollIndicator, on: self).store(in: &store)
    theme.$bounces.weakAssign(to: \.bounces, on: self).store(in: &store)
    theme.$bouncesZoom.weakAssign(to: \.bouncesZoom, on: self).store(in: &store)
    theme.$scrollsToTop.weakAssign(to: \.scrollsToTop, on: self).store(in: &store)
    theme.$automaticallyAdjustsScrollIndicatorInsets
      .weakAssign(to: \.automaticallyAdjustsScrollIndicatorInsets, on: self).store(in: &store)
    theme.$contentInsetAdjustmentBehavior
      .weakAssign(to: \.contentInsetAdjustmentBehavior, on: self).store(in: &store)
    theme.$keyboardDismissMode.weakAssign(to: \.keyboardDismissMode, on: self).store(in: &store)
  }
}

public class TextViewComponentTheme: ObservableObject {
  public var customType: UITextView.Type
  
  @Published public var backgroundColor: UIColor?
  @Published public var textColor: UIColor?
  @Published public var textFont: UIFont?
  @Published public var usesStandardTextScaling: Bool
  
  @Published public var dataDetectorTypes: UIDataDetectorTypes
  @Published public var linkTextAttributes: [NSAttributedString.Key: Any]
  
  @Published public var isEditable: Bool
  @Published public var isExclusiveTouch: Bool
  
  @Published public var scrollView: ScrollViewComponentTheme

  @Published public var textContainerInset: UIEdgeInsets
  
  public init(
    customType: UITextView.Type,
    backgroundColor: UIColor,
    textColor: UIColor ,
    textFont: UIFont ,
    usesStandardTextScaling: Bool,
    dataDetectorTypes: UIDataDetectorTypes ,
    linkTextAttributes: [NSAttributedString.Key: Any],
    isEditable: Bool,
    isExclusiveTouch: Bool,
    scrollView: ScrollViewComponentTheme,
    textContainerInset: UIEdgeInsets
  ) {
    self.customType = customType
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.textFont = textFont
    self.usesStandardTextScaling = usesStandardTextScaling
    self.dataDetectorTypes = .all
    self.linkTextAttributes = [:]
    self.isEditable = isEditable
    self.isExclusiveTouch = isExclusiveTouch
    self.scrollView = scrollView
    self.textContainerInset = textContainerInset
  }
}

extension UITextView {
  public func theming(_ theme: TextViewComponentTheme, cancelIn store: inout Set<AnyCancellable>) {
    theme.$backgroundColor.weakAssign(to: \.backgroundColor, on: self).store(in: &store)
    theme.$textColor.weakAssign(to: \.textColor, on: self).store(in: &store)
    theme.$textFont.weakAssign(to: \.font, on: self).store(in: &store)
    theme.$usesStandardTextScaling.weakAssign(to: \.usesStandardTextScaling, on: self).store(in: &store)
    
    theme.$dataDetectorTypes.weakAssign(to: \.dataDetectorTypes, on: self).store(in: &store)
    theme.$linkTextAttributes.weakAssign(to: \.linkTextAttributes, on: self).store(in: &store)
    
    theme.$isEditable.weakAssign(to: \.isEditable, on: self).store(in: &store)
    theme.$isExclusiveTouch.weakAssign(to: \.isExclusiveTouch, on: self).store(in: &store)
    
    var localStore = Set<AnyCancellable>()
    theme.$scrollView.sink { [weak self] scrollTheme in
      self?.theming(scrollTheme, cancelIn: &localStore)
    }.store(in: &store)
    store.formUnion(localStore)
    
    theme.$textContainerInset.weakAssign(to: \.textContainerInset, on: self).store(in: &store)
  }
}

public class InputTextViewComponentTheme: TextViewComponentTheme {

  @Published public var typingAttributes: [NSAttributedString.Key: Any] = [:]
  
  // UITextInputTraits
  @Published public var autocapitalizationType: UITextAutocapitalizationType = .sentences
  @Published public var autocorrectionType: UITextAutocorrectionType = .default
  @Published public var spellCheckingType: UITextSpellCheckingType = .default
  @Published public var smartQuotesType: UITextSmartQuotesType = .default
  @Published public var smartDashesType: UITextSmartDashesType = .default
  @Published public var smartInsertDeleteType: UITextSmartInsertDeleteType = .default
  @Published public var keyboardType: UIKeyboardType = .default
  @Published public var keyboardAppearance: UIKeyboardAppearance = .default
  @Published public var textContentType: UITextContentType? = nil
  
  public init(
    customType: UITextView.Type = UITextView.self,
    backgroundColor: UIColor = .clear,
    textColor: UIColor = .black,
    textFont: UIFont = .preferredFont(forTextStyle: .body),
    usesStandardTextScaling: Bool = true,
    dataDetectorTypes: UIDataDetectorTypes = .all,
    linkTextAttributes: [NSAttributedString.Key: Any] = [:],
    isEditable: Bool = false,
    isExclusiveTouch: Bool = false,
    scrollView: ScrollViewComponentTheme = .enabled,
    textContainerInset: UIEdgeInsets = .zero,
    typingAttributes: [NSAttributedString.Key: Any] = [:],
    autocapitalizationType: UITextAutocapitalizationType = .sentences,
    autocorrectionType: UITextAutocorrectionType = .default,
    spellCheckingType: UITextSpellCheckingType = .default,
    smartQuotesType: UITextSmartQuotesType = .default,
    smartDashesType: UITextSmartDashesType = .default,
    smartInsertDeleteType: UITextSmartInsertDeleteType = .default,
    keyboardType: UIKeyboardType = .default,
    keyboardAppearance: UIKeyboardAppearance = .default,
    textContentType: UITextContentType? = nil
  ) {
    self.typingAttributes = typingAttributes
    self.autocapitalizationType = autocapitalizationType
    self.autocorrectionType = autocorrectionType
    self.spellCheckingType = spellCheckingType
    self.smartQuotesType = smartQuotesType
    self.smartDashesType = smartDashesType
    self.smartInsertDeleteType = smartInsertDeleteType
    self.keyboardType = keyboardType
    self.keyboardAppearance = keyboardAppearance
    self.textContentType = textContentType
    
    super.init(
      customType: customType,
      backgroundColor: backgroundColor,
      textColor: textColor,
      textFont: textFont,
      usesStandardTextScaling: usesStandardTextScaling,
      dataDetectorTypes: dataDetectorTypes,
      linkTextAttributes: linkTextAttributes,
      isEditable: isEditable,
      isExclusiveTouch: isExclusiveTouch,
      scrollView: scrollView,
      textContainerInset: textContainerInset
    )
  }
}

extension UITextView {
  func theming(_ theme: InputTextViewComponentTheme, cancelIn store: inout Set<AnyCancellable>) {
    // Call Super class
    self.theming(theme as TextViewComponentTheme, cancelIn: &store)
    
    theme.$typingAttributes.weakAssign(to: \.typingAttributes, on: self).store(in: &store)
    theme.$autocapitalizationType.weakAssign(to: \.autocapitalizationType, on: self).store(in: &store)
    theme.$spellCheckingType.weakAssign(to: \.spellCheckingType, on: self).store(in: &store)
    theme.$smartQuotesType.weakAssign(to: \.smartQuotesType, on: self).store(in: &store)
    theme.$smartDashesType.weakAssign(to: \.smartDashesType, on: self).store(in: &store)
    theme.$smartInsertDeleteType.weakAssign(to: \.smartInsertDeleteType, on: self).store(in: &store)
    theme.$keyboardType.weakAssign(to: \.keyboardType, on: self).store(in: &store)
    theme.$keyboardAppearance.weakAssign(to: \.keyboardAppearance, on: self).store(in: &store)
    theme.$textContentType.weakAssign(to: \.textContentType, on: self).store(in: &store)
  }
}

// MARK: - LinkView

public class LinkViewComponentTheme: ObservableObject {
  public var cacheProvider: LinkMetadataService
  
  @Published public var layoutMargin: UIEdgeInsets

  public init(
    cacheProvider: LinkMetadataService,
    layoutMargin: UIEdgeInsets
  ) {
    self.cacheProvider = cacheProvider
    self.layoutMargin = layoutMargin
  }
}

// MARK: - BasicComponentTheme

public class BasicComponentTheme: ObservableObject {
  // Appearance
  @Published public var imageView: ImageComponentTheme
  @Published public var primaryLabel: LabelComponentTheme
  @Published public var secondaryLabel: LabelComponentTheme
  @Published public var tertiaryLabel: LabelComponentTheme
  @Published public var quaternaryLabel: LabelComponentTheme
  
  public init(
    imageView: ImageComponentTheme,
    primaryLabel: LabelComponentTheme,
    secondaryLabel: LabelComponentTheme? = nil,
    tertiaryLabel: LabelComponentTheme? = nil,
    quaternaryLabel: LabelComponentTheme? = nil
  ) {
    self.imageView = imageView
    self.primaryLabel = primaryLabel
    self.secondaryLabel = secondaryLabel ?? primaryLabel
    self.tertiaryLabel = tertiaryLabel ?? primaryLabel
    self.quaternaryLabel = quaternaryLabel ?? primaryLabel
  }
  
  public static var empty: BasicComponentTheme {
    return BasicComponentTheme(
      imageView: .empty,
      primaryLabel: .empty,
      secondaryLabel: .empty,
      tertiaryLabel: .empty,
      quaternaryLabel: .empty
    )
  }
}
