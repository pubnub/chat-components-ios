//
//  MessageListComponentTheme.swift
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

public class MessageListComponentTheme: ViewControllerComponentTheme {

  @Published public var collectionViewTheme: CollectionViewComponentTheme
  @Published public var messageInputComponent: MessageInputComponentTheme
  @Published public var incomingItemTheme: MessageListCellComponentTheme
  @Published public var authorItemTheme: MessageListCellComponentTheme
  
  @Published public var typingIndicatorCellTheme: TypingIndicatorCellTheme
  public var enableReactions: Bool

  
  public init(
    controllerType: ComponentViewController.Type,
    backgroundColor: UIColor?,
    navigationBarTheme: NavigationBarTheme,
    collectionViewTheme: CollectionViewComponentTheme,
    messageInputComponent: MessageInputComponentTheme,
    incomingItemTheme: MessageListCellComponentTheme,
    authorItemTheme: MessageListCellComponentTheme?,
    typingIndicatorCellTheme: TypingIndicatorCellTheme,
    enableReactions: Bool
  ) {
    self.messageInputComponent = messageInputComponent
    self.collectionViewTheme = collectionViewTheme
    self.incomingItemTheme = incomingItemTheme
    self.authorItemTheme = authorItemTheme ?? incomingItemTheme
    
    self.typingIndicatorCellTheme = typingIndicatorCellTheme
    
    self.enableReactions = enableReactions
    
    super.init(
      controllerType: controllerType,
      backgroundColor: backgroundColor,
      navigationBar: navigationBarTheme
    )
  }
}

public class MessageListCellComponentTheme: CollectionViewCellTheme {
  
  // Appearance
  @Published public var alignment: UICollectionViewCell.Alignment
  @Published public var maxWidthPercentage: CGFloat
  @Published public var bubbleContainerTheme: BubbleComponentTheme
  @Published public var contentTextTheme: TextViewComponentTheme
  @Published public var itemTheme: BasicComponentTheme
  @Published public var dateFormatter: DateFormatter

  public init(
    textMessageContentCellType: CollectionViewCellComponent.Type,
    backgroundColor: UIColor?,
    highlightColor: UIColor?,
    selectedColor: UIColor?,
    alignment: UICollectionViewCell.Alignment,
    maxWidthPercentage: CGFloat,
    bubbleContainerTheme: BubbleComponentTheme,
    contentTextTheme: TextViewComponentTheme,
    itemTheme: BasicComponentTheme,
    dateFormatter: DateFormatter
  ) {
    self.alignment = alignment
    self.maxWidthPercentage = maxWidthPercentage
    self.bubbleContainerTheme = bubbleContainerTheme
    self.contentTextTheme = contentTextTheme
    self.itemTheme = itemTheme
    self.dateFormatter = dateFormatter

    super.init(
      customType: textMessageContentCellType,
      backgroundColor: backgroundColor,
      highlightColor: highlightColor,
      selectedColor: selectedColor
    )
  }
}

// MARK: - Default Group Chat

extension MessageListComponentTheme {
  public static var pubnubGroupChat: MessageListComponentTheme {
    return MessageListComponentTheme(
      controllerType: CollectionViewComponent.self,
      backgroundColor: .systemBackground,
      navigationBarTheme: .pubnubGroupChatMessageList,
      collectionViewTheme:  .pubnubGroupChat,
      messageInputComponent: .pubnubGroupChat,
      incomingItemTheme: .incomingGroupChat,
      authorItemTheme: nil,
      typingIndicatorCellTheme: AnimatedTypingIndicatorCellTheme(
        cellType: IMessageTypingIndicatorCell.self,
        contentViewType: IMessageTypingBubbleView.self,
        backgroundColor: .clear,
        highlightColor: .clear,
        selectedColor: .clear,
        primaryContentColor: .systemGray5,
        secondaryContentColor: .systemGray2,
        animationEnabled: true,
        pulsing: true,
        bounces: true,
        bounceDelay: 0.33,
        bounceOffset: 0.25,
        fades: true
      ),
      enableReactions: false
    )
  }
}

extension CollectionViewComponentTheme {
  public static var pubnubGroupChat: CollectionViewComponentTheme {
    return CollectionViewComponentTheme(
      viewType: UICollectionView.self,
      layoutType: CollectionViewChatLayout.self,
      headerType: ReusableLabelViewComponent.self,
      footerType: ReusableLabelViewComponent.self,
      backgroundColor: .secondarySystemBackground,
      scrollViewTheme: .enabled,
      refreshControlTheme: .init(
        pullToRefreshTitle: .init(string: "Pull to Refresh"),
        pullToRefreshTintColor: nil
      ),
      prefetchIndexThreshold: 35,
      isPrefetchingEnabled: false // https://openradar.appspot.com/40926834
    )
  }
}

extension MessageListCellComponentTheme {
  public static var incomingGroupChat: MessageListCellComponentTheme {
    return MessageListCellComponentTheme(
      textMessageContentCellType: MessageListItemCell.self,
      backgroundColor: .clear,
      highlightColor: .clear,
      selectedColor: .clear,
      alignment: .leading,
      maxWidthPercentage: 0.65,
      bubbleContainerTheme: BubbleComponentTheme(
        alignment: .leading,
        containerType: .tailed,
        backgroundColor: .systemBlue,
        tailSize: 5,
        layoutMargin: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
      ),
      contentTextTheme: TextViewComponentTheme(
        customType: UITextView.self,
        backgroundColor: .clear,
        textColor: .black,
        textFont: AppearanceTemplate.Font.body,
        usesStandardTextScaling: false,
        dataDetectorTypes: .all,
        linkTextAttributes: [:],
        isEditable: false,
        isExclusiveTouch: false,
        scrollView: .disabled,
        textContainerInset: .zero
      ),
      itemTheme: .pubnubGroupChannelList,
      dateFormatter: .messageInline
    )
  }
}

extension NavigationBarTheme {
  public static var pubnubGroupChatMessageList: NavigationBarTheme {
    return NavigationBarTheme(
      largeTitleDisplayMode: .always,
      standardAppearance: UINavigationBarAppearance(),
      compactAppearance: nil,
      scrollEdgeAppearance: nil,
      customTitleView: .pubnubGroupChannelNavigationView,
      barButtonThemes: ["memberPresenceCount": .memberPresenceCount]
    )
  }
}

extension BarButtonItemTheme {
  public static var memberPresenceCount: BarButtonItemTheme {
    return BarButtonItemTheme(
      viewType: BarButtonItemComponent.self,
      buttonTheme: ButtonComponentTheme(
        backgroundColor: nil,
        buttonType: .system,
        tintColor: nil,
        title: .empty,
        titleHighlighted: .empty,
        titleFont: nil,
        image: ButtonImageStateTheme(
          image: AppearanceTemplate.Image.members,
          backgroundImage: nil
        ),
        imageHighlighted: .empty
      ),
      buttonItemAppearance: UIBarButtonItemAppearance()
    )
  }
}
