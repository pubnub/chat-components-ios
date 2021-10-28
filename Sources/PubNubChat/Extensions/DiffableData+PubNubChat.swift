//
//  DiffableData+PubNubChat.swift
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

extension NSDiffableDataSourceSnapshotReference {
  /// Less verbose typecasting from a snapshot reference to a snapshot
  func cast<S: Hashable, I: Hashable>() -> NSDiffableDataSourceSnapshot<S,I> {
    return self as NSDiffableDataSourceSnapshot<S,I>
  }
}

extension UICollectionViewDiffableDataSource {
  func itemIdentifier(for indexPath: IndexPath?) -> ItemIdentifierType? {
    guard let indexPath = indexPath else {
      return nil
    }
    
    return itemIdentifier(for: indexPath)
  }
}

extension IndexPath {
  var previousItem: IndexPath? {
    if item == 0 { return nil }
    
    return IndexPath(item: item-1, section: section)
  }
}
