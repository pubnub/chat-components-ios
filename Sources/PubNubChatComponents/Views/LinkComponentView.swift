//
//  LinkComponentView.swift
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
import LinkPresentation
import Combine
import CoreData

import PubNub

import ChatLayout

final public class LinkComponentView: UIView {

  var linkView: LPLinkView?

  private var viewPortWidth: CGFloat = 300
  private var maxWidthPercentage: CGFloat = 0.65

  private var linkWidthConstraint: NSLayoutConstraint?
  private var linkHeightConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
 
  func configure(
    urlPublisher: AnyPublisher<URL?, Never>,
    cache: LinkMetadataService,
    reloadDelegate: ReloadCellDelegate?,
    cancelIn store: inout Set<AnyCancellable>
  ) {
    urlPublisher
      .map { $0! }
      .handleEvents(
        receiveOutput: { [weak self] url in
          if let metadata = cache.metadata(forURL: url) {
            self?.setupLinkView(LPLinkView(metadata: metadata))
          } else {
            self?.setupLinkView(LPLinkView(url: url))
          }
        },
        receiveCancel: { [weak self] in
          self?.linkView?.removeFromSuperview()
          self?.linkView = nil
        }
      )
      .flatMap {
        cache.fetchMetadata(forURL: $0, provider: LPMetadataProvider())
          .replaceError(with: .init())
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self, weak reloadDelegate] metadata in
        if self?.linkView?.metadata == metadata {
          self?.setupSize()
        } else {
          reloadDelegate?.reloadComponentCell()
        }
      }
      .store(in: &store)
  }

  private func setupLinkView(_ newLinkView: LPLinkView) {
    UIView.performWithoutAnimation {
      addSubview(newLinkView)
      newLinkView.translatesAutoresizingMaskIntoConstraints = false
      newLinkView.topAnchor.constraint(equalTo: topAnchor).isActive = true
      newLinkView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
      newLinkView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
      newLinkView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

      linkWidthConstraint = newLinkView.widthAnchor.constraint(equalToConstant: 300)
      linkWidthConstraint?.priority = UILayoutPriority(999)
      linkWidthConstraint?.isActive = true

      linkHeightConstraint = newLinkView.heightAnchor.constraint(equalToConstant: newLinkView.intrinsicContentSize.height)
      linkHeightConstraint?.priority = UILayoutPriority(999)
      linkHeightConstraint?.isActive = true

      self.linkView = newLinkView
    }
  }

  private func setupSize() {
    guard let linkView = linkView else {
        return
    }
    let contentSize = linkView.intrinsicContentSize
    let maxWidth = min(viewPortWidth, contentSize.width)

    let newContentRect = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: contentSize.height))

    linkWidthConstraint?.constant = newContentRect.width
    linkHeightConstraint?.constant = newContentRect.height

    linkView.bounds = newContentRect
    linkView.sizeToFit()

    setNeedsLayout()
    layoutIfNeeded()
  }
}
