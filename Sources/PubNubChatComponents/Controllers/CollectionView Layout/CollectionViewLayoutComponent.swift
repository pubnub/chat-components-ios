//
//  CollectionViewLayoutComponent.swift
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

// MARK: Default View Layout

public protocol CollectionViewLayoutComponent: UICollectionViewLayout {
  static func create(usingSupplimentaryItems: Bool) -> UICollectionViewLayout
}

// MARK: - Default impl.

open class TableCollectionViewLayout: UICollectionViewLayout, CollectionViewLayoutComponent {
  static public func create(usingSupplimentaryItems: Bool) -> UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .fractionalHeight(1.0)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(50.0)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitems: [item]
    )
    
    let section = NSCollectionLayoutSection(group: group)
    
    if usingSupplimentaryItems {
      let headerSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(5.0)
      )
      let header = NSCollectionLayoutBoundarySupplementaryItem(
        layoutSize: headerSize,
        elementKind: UICollectionView.elementKindSectionHeader,
        alignment: .top
      )
      section.boundarySupplementaryItems = [header]
    }
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 10, leading: 10, bottom: 0, trailing: 0
    )
    
    let config = UICollectionViewCompositionalLayoutConfiguration()
    config.interSectionSpacing = 10
    
    let layout = UICollectionViewCompositionalLayout(
      section: section,
      configuration: config
    )
    
    return layout
  }
}

// MARK: - Message impl.

extension ChatLayout: CollectionViewLayoutComponent {
  public static func create(usingSupplimentaryItems: Bool) -> UICollectionViewLayout {
    let chatLayout = ChatLayout()

    chatLayout.settings.interItemSpacing = 8
    chatLayout.settings.interSectionSpacing = 8
    chatLayout.settings.additionalInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
    chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
    
    return chatLayout
  }
}
