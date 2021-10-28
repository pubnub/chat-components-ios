//
//  ChannelAPI.swift
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
import Combine

import PubNub

public struct PaginationError<Request>: Error {
  public var request: Request
  public var error: Error
}

public protocol PubNubChannelAPI {
  func fetchAll<Custom: ChannelCustomData>(
    channels request: ObjectsFetchRequest,
    into: Custom.Type,
    completion: ((Result<(channels: [ChatChannel<Custom>], next: ObjectsFetchRequest?), Error>) -> Void)?
  )

  func fetch<Custom: ChannelCustomData>(
    channel request: ObjectMetadataIdRequest,
    into: Custom.Type,
    completion: ((Result<ChatChannel<Custom>, Error>) -> Void)?
  )

  func set<Custom: ChannelCustomData>(
    channel request: ChannelMetadataRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatChannel<Custom>, Error>) -> Void)?
  )

  func remove(
    channel request: ObjectRemoveRequest,
    completion: ((Result<String, Error>) -> Void)?
  )
}

extension PubNubChannelAPI {
  
  func fetchAllPublisher<Custom: ChannelCustomData>(
    channels request: ObjectsFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(channels: [ChatChannel<Custom>], next: ObjectsFetchRequest?), Error> {
    return Future { promise in
      fetchAll(channels: request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  
  public func fetchAllPagesPublisher<Custom: ChannelCustomData>(
    channels request: ObjectsFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatChannel<Custom>], ObjectsFetchRequest?), PaginationError<ObjectsFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<ObjectsFetchRequest, PaginationError<ObjectsFetchRequest>>(request)

    return pagedPublisher
      .flatMap({ request in
        fetchAllPublisher(channels: request, into: customType)
          .mapError { PaginationError<ObjectsFetchRequest>(request: request, error: $0) }
      })
      .handleEvents(receiveOutput: { output in
        if let request = output.next {
          pagedPublisher.send(request)
        } else {
          pagedPublisher.send(completion: .finished)
        }
      })
      .map { ($0.channels, $0.next) }
      .eraseToAnyPublisher()
  }
}

// MARK: - PubNub Ext

extension PubNub: PubNubChannelAPI {
  public func fetchAll<Custom: ChannelCustomData>(
    channels request: ObjectsFetchRequest,
    into: Custom.Type,
    completion: ((Result<(channels: [ChatChannel<Custom>], next: ObjectsFetchRequest?), Error>) -> Void)?
  ) {
    allChannelMetadata(
      include: request.include,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(result.map {
        ($0.channels.compactMap { try? $0.transcode() }, request.next(page: $0.next))
      })
    }
  }

  public func fetch<Custom: ChannelCustomData>(
    channel request: ObjectMetadataIdRequest,
    into: Custom.Type,
    completion: ((Result<ChatChannel<Custom>, Error>) -> Void)?
  ) {
    fetch(
      channel: request.metadataId,
      include: request.includeCustom,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(
        result
          .flatMap { do { return .success(try $0.transcode()) } catch { return .failure(error) } }
      )
    }
  }

  public func set<Custom: ChannelCustomData>(
    channel request: ChannelMetadataRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatChannel<Custom>, Error>) -> Void)?
  ) {
    set(
      channel: request.channel,
      include: request.includeCustom,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(result.flatMap { do { return .success(try $0.transcode()) } catch { return .failure(error) } })
    }
  }

  public func remove(
    channel request: ObjectRemoveRequest,
    completion: ((Result<String, Error>) -> Void)?
  ) {
    remove(
      channel: request.metadataId,
      custom: .init(customConfiguration: request.config?.mergeChatConsumerID()),
      completion: completion
    )
  }
}

// MARK: - Requests

public struct ChannelMetadataRequest<Custom: ChannelCustomData> {
  public let requestId: String = UUID().uuidString

  public var channel: ChatChannel<Custom>
  public var includeCustom: Bool
  
  public var config: PubNubConfiguration?
  
  public init(
    channel: ChatChannel<Custom>,
    includeCustom: Bool = true,
    config: PubNubConfiguration? = nil
  ) {
    self.channel = channel
    self.includeCustom = includeCustom
    self.config = config
  }
}

extension ChannelMetadataRequest: Equatable {
  public static func == (lhs: ChannelMetadataRequest, rhs: ChannelMetadataRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

public struct ObjectRemoveRequest: Equatable {
  public let requestId: String = UUID().uuidString
  public var metadataId: String
  public var config: PubNubConfiguration?
  
  public init(
    metadataId: String,
    config: PubNubConfiguration? = nil
  ) {
    self.metadataId = metadataId
    self.config = config
  }
}

// MARK: - Extensions

extension PubNubChannelMetadataChangeset {
  func apply<T: PubNubChannelMetadata>(to object: PubNubChannelMetadata, into _: T.Type) -> T? {
    return apply(to: object) as? T
  }
}

