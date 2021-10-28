//
//  MemberListComponentTheme.swift
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


public class MemberListComponentTheme: ViewControllerComponentTheme {
  
  @Published public var collectionViewTheme: CollectionViewComponentTheme
  @Published public var sectionHeaderLabel: LabelComponentTheme
  @Published public var cellTheme: MemberListCellComponentTheme
  
  public init(
    controllerType: ComponentViewController.Type = CollectionViewComponent.self,
    backgroundColor: UIColor,
    navigationBarTheme: NavigationBarTheme,
    collectionViewTheme: CollectionViewComponentTheme,
    sectionHeaderLabel: LabelComponentTheme,
    cellTheme: MemberListCellComponentTheme
  ) {
    self.collectionViewTheme = collectionViewTheme
    self.sectionHeaderLabel = sectionHeaderLabel
    self.cellTheme = cellTheme
    super.init(
      controllerType: controllerType,
      backgroundColor: backgroundColor,
      navigationBar: navigationBarTheme
    )
  }
}

extension MemberListComponentTheme {
  public static var pubnubDefaultGroupMemberList: MemberListComponentTheme {
    return MemberListComponentTheme(
      controllerType: CollectionViewComponent.self,
      backgroundColor: .secondarySystemBackground,
      navigationBarTheme: .pubnubGroupChatMemberList,
      collectionViewTheme: .pubnubDefaultGroupCollectionView,
      sectionHeaderLabel: .pubnubDefaultGroupSectionHeader,
      cellTheme: .pubnubDefaultGroupMemberCell
    )
  }
}

public class MemberListCellComponentTheme: CollectionViewCellTheme {
  // Appearance
  @Published public var itemTheme: BasicComponentTheme
  
  public init(
    cellType: CollectionViewCellComponent.Type,
    backgroundColor: UIColor = .clear,
    highlightColor: UIColor = .clear,
    selectedColor: UIColor = .clear,
    itemTheme: BasicComponentTheme = .pubnubGroupMemberList
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

extension MemberListCellComponentTheme {
  public static var pubnubDefaultGroupMemberCell: MemberListCellComponentTheme {
    return MemberListCellComponentTheme(
      cellType: ChannelMemberComponentCell.self,
      backgroundColor: .clear,
      highlightColor: .clear,
      selectedColor: .clear,
      itemTheme: .pubnubGroupChannelList
    )
  }
}

extension BasicComponentTheme {
  public static var pubnubGroupMemberList: BasicComponentTheme {
    return BasicComponentTheme(
      imageView: .pubnubDefaultGroupInline,
      primaryLabel: .pubnubDefaultGroupListItemPrimary,
      secondaryLabel: .pubnubDefaultGroupListItemSecondary,
      tertiaryLabel: nil,
      quaternaryLabel: nil
    )
  }
}

extension NavigationBarTheme {
  public static var pubnubGroupChatMemberList: NavigationBarTheme {
    return NavigationBarTheme(
      largeTitleDisplayMode: .always,
      standardAppearance: UINavigationBarAppearance(),
      compactAppearance: nil,
      scrollEdgeAppearance: nil,
      customTitleView: .empty,
      barButtonThemes: [:]
    )
  }
}
