//
//  LinkMetadataService.swift
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

import Foundation
import LinkPresentation
import Combine

import PubNub
import PubNubChat

public protocol LinkMetadataService: CacheProvider {
  func fetchMetadata(
    forURL url: URL,
    provider: LPMetadataProvider
  ) -> AnyPublisher<LPLinkMetadata, Error>
  
  func metadata(forURL url: URL) -> LPLinkMetadata?
  func store(_ metadata: LPLinkMetadata, forURL url: URL?)
}

extension InMemoryCache: LinkMetadataService {
  public func fetchMetadata(
    forURL url: URL,
    provider: LPMetadataProvider
  ) -> AnyPublisher<LPLinkMetadata, Error> {
    return Future { [weak self] promise in
      if let metadata = self?.metadata(forURL: url) {
        promise(.success(metadata))
        return
      }
      
      provider.startFetchingMetadata(for: url) { [weak self] (metadata, error) in
        if let error = error {
          promise(.failure(error))
        }
        else if let metadata = metadata {
          self?.store(metadata, forURL: url)
          promise(.success(metadata))
        } else {
          PubNub.log.error("LPMetadataProvider startFetchingMetadata for \(url) failed to return with neither error nor metadata")
          promise(.failure(ChatError.missingRequiredData))
        }
      }
    }.eraseToAnyPublisher()
  }
  
  public func metadata(forURL url: URL) -> LPLinkMetadata? {
    return self.internalCache.object(forKey: url.absoluteString as NSString) as? LPLinkMetadata
  }
  
  public func store(_ metadata: LPLinkMetadata, forURL url: URL?) {
    guard let urlKey = url?.absoluteString else { return }
    self.internalCache.setObject(metadata, forKey: urlKey as NSString)
  }
}
