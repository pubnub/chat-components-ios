//
//  ChannelListComponentTheme.swift
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


public class ChannelListComponentTheme: ViewControllerComponentTheme {
  
  @Published public var collectionViewTheme: CollectionViewComponentTheme
  @Published public var sectionHeaderTheme: BasicComponentTheme
  @Published public var cellTheme: ChannelListCellComponentTheme
  
  public init(
    controllerType: ComponentViewController.Type,
    backgroundColor: UIColor,
    navigationBarTheme: NavigationBarTheme,
    collectionViewTheme: CollectionViewComponentTheme,
    sectionHeaderTheme: BasicComponentTheme,
    cellTheme: ChannelListCellComponentTheme
  ) {
    self.collectionViewTheme = collectionViewTheme
    self.sectionHeaderTheme = sectionHeaderTheme
    self.cellTheme = cellTheme
    super.init(
      controllerType: controllerType,
      backgroundColor: backgroundColor,
      navigationBar: navigationBarTheme
    )
  }
}

extension ChannelListComponentTheme {
  public static var pubnubDefaultGroupChannelList: ChannelListComponentTheme {
    return ChannelListComponentTheme(
      controllerType: CollectionViewComponent.self,
      backgroundColor: .secondarySystemBackground,
      navigationBarTheme: .pubnubGroupChatChannelList,
      collectionViewTheme: .pubnubDefaultGroupCollectionView,
      sectionHeaderTheme: BasicComponentTheme(
        imageView: .empty,
        primaryLabel: .pubnubDefaultGroupSectionHeader,
        secondaryLabel: nil,
        tertiaryLabel: nil,
        quaternaryLabel: nil
      ),
      cellTheme: .pubnubDefaultGroupChannelCell
    )
  }
}

extension CollectionViewComponentTheme {
  public static var pubnubDefaultGroupCollectionView: CollectionViewComponentTheme {
    return CollectionViewComponentTheme(
      viewType: UICollectionView.self,
      layoutType: TableCollectionViewLayout.self,
      headerType: ReusableLabelViewComponent.self,
      footerType: ReusableLabelViewComponent.self,
      backgroundColor: .systemBackground,
      scrollViewTheme: .init(
        isScrollEnabled: true
      ),
      refreshControlTheme: nil,
      prefetchIndexThreshold: nil,
      isPrefetchingEnabled: true
    )
  }
}

public class ChannelListCellComponentTheme: CollectionViewCellTheme {
  // Appearance
  @Published public var itemTheme: BasicComponentTheme

  public init(
    cellType: CollectionViewCellComponent.Type,
    backgroundColor: UIColor,
    highlightColor: UIColor,
    selectedColor: UIColor,
    itemTheme: BasicComponentTheme
  ) {
    self.itemTheme = itemTheme

    super.init(
      customType: cellType,
      backgroundColor: backgroundColor,
      highlightColor: highlightColor,
      selectedColor: selectedColor
    )
  }
}

extension ChannelListCellComponentTheme {
  public static var pubnubDefaultGroupChannelCell: ChannelListCellComponentTheme {
    return ChannelListCellComponentTheme(
      cellType: ChannelMemberComponentCell.self,
      backgroundColor: .clear,
      highlightColor: .clear,
      selectedColor: .systemGray4,
      itemTheme: .pubnubGroupChannelList
    )
  }
}

extension ImageComponentTheme {
  public static var pubnubDefaultGroupInline: ImageComponentTheme {
    return ImageComponentTheme(
      customType: PubNubAvatarComponentView.self,
      localImage: AppearanceTemplate.Image.avatar,
      cornerRadius: 15,
      margin: .init(top: .zero, left: 10.0, bottom: .zero, right: 5.0)
    )
  }
}

extension LabelComponentTheme {
  public static var pubnubDefaultGroupListItemPrimary: LabelComponentTheme {
    return LabelComponentTheme(
      customType: PubNubLabelComponentView.self,
      textFont: AppearanceTemplate.Font.caption1,
      textColor: AppearanceTemplate.Color.label,
      adjustsFontForContentSizeCategory: true,
      textAlignment: .natural,
      textMargin: .zero
    )
  }
  
  public static var pubnubDefaultGroupListItemSecondary: LabelComponentTheme {
    return LabelComponentTheme(
      customType: PubNubLabelComponentView.self,
      textFont: AppearanceTemplate.Font.caption2,
      textColor: AppearanceTemplate.Color.secondaryLabel,
      adjustsFontForContentSizeCategory: true,
      textAlignment: .natural,
      textMargin: .zero
    )
  }
  
  public static var pubnubDefaultGroupNavigationTitle: LabelComponentTheme {
    return LabelComponentTheme(
      customType: PubNubLabelComponentView.self,
      textFont: AppearanceTemplate.Font.title2.bold,
      textColor: AppearanceTemplate.Color.label,
      adjustsFontForContentSizeCategory: true,
      textAlignment: .natural,
      textMargin: .zero
    )
  }
  
  public static var pubnubDefaultGroupSectionHeader: LabelComponentTheme {
    return LabelComponentTheme(
      customType: PubNubLabelComponentView.self,
      textFont: AppearanceTemplate.Font.title1.bold,
      textColor: AppearanceTemplate.Color.label,
      adjustsFontForContentSizeCategory: true,
      textAlignment: .natural,
      textMargin: .zero
    )
  }
}

extension BasicComponentTheme {
  public static var pubnubGroupChannelList: BasicComponentTheme {
    return BasicComponentTheme(
      imageView: .pubnubDefaultGroupInline,
      primaryLabel: .pubnubDefaultGroupListItemPrimary,
      secondaryLabel: .pubnubDefaultGroupListItemSecondary
    )
  }
  
  public static var pubnubGroupChannelNavigationView: BasicComponentTheme {
    return BasicComponentTheme(
      imageView: .pubnubDefaultGroupInline,
      primaryLabel: .pubnubDefaultGroupNavigationTitle
    )
  }
}

extension NavigationBarTheme {
  public static var pubnubGroupChatChannelList: NavigationBarTheme {
    return NavigationBarTheme(
      largeTitleDisplayMode: .always,
      standardAppearance: UINavigationBarAppearance(),
      compactAppearance: nil,
      scrollEdgeAppearance: nil,
      customTitleView: .pubnubGroupChannelNavigationView,
      barButtonThemes: [:]
    )
  }
}
