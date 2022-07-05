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
import PubNubSpace

public struct PaginationError<Request>: Error {
  public var request: Request
  public var error: Error
}

public protocol PubNubChannelAPI {
  func fetch<Custom: ChannelCustomData>(
    channels request: ChannelsFetchRequest,
    into: Custom.Type,
    completion: @escaping ((Result<(channels: [ChatChannel<Custom>], next: ChannelsFetchRequest?), Error>) -> Void)
  )

  func fetch<Custom: ChannelCustomData>(
    channel request: ChatChannelRequest<Custom>,
    into: Custom.Type,
    completion: @escaping ((Result<ChatChannel<Custom>, Error>) -> Void)
  )

  func create<Custom: ChannelCustomData>(
    channel request: ChatChannelRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatChannel<Custom>, Error>) -> Void)?
  )
  
  func update<Custom: ChannelCustomData>(
    channel request: ChatChannelRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatChannel<Custom>, Error>) -> Void)?
  )

  func remove<Custom: ChannelCustomData>(
    channel request: ChatChannelRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

extension PubNubChannelAPI {
  
  func fetchPublisher<Custom: ChannelCustomData>(
    channels request: ChannelsFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(channels: [ChatChannel<Custom>], next: ChannelsFetchRequest?), Error> {
    return Future { promise in
      fetch(channels: request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  
  public func fetchPagesPublisher<Custom: ChannelCustomData>(
    channels request: ChannelsFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatChannel<Custom>], ChannelsFetchRequest?), PaginationError<ChannelsFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<ChannelsFetchRequest, PaginationError<ChannelsFetchRequest>>(request)

    return pagedPublisher
      .flatMap({ request in
        fetchPublisher(channels: request, into: customType)
          .mapError { PaginationError<ChannelsFetchRequest>(request: request, error: $0) }
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

extension PubNubProvider {
  public func fetch<Custom: ChannelCustomData>(
    channels request: ChannelsFetchRequest,
    into: Custom.Type,
    completion: @escaping ((Result<(channels: [ChatChannel<Custom>], next: ChannelsFetchRequest?), Error>) -> Void)
  ) {
    spaceInterface.fetchSpaces(
      includeCustom: request.includeCustom,
      includeTotalCount: request.includeTotalCount,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      requestConfig: .init(customConfiguration: request.config)
    ) { result in
      completion(result.map { ($0.spaces.map { ChatChannel(pubnub: $0) }, request.next(page: $0.next)) })
    }
  }

  public func fetch<Custom: ChannelCustomData>(
    channel request: ChatChannelRequest<Custom>,
    into: Custom.Type,
    completion: @escaping ((Result<ChatChannel<Custom>, Error>) -> Void)
  ) {
    spaceInterface.fetchSpace(
      spaceId: request.channel.id,
      includeCustom: request.includeCustom,
      requestConfig: .init(customConfiguration: request.config)
    ) { result in
      completion(result.map { ChatChannel(pubnub: $0) })
    }
  }

  public func create<Custom: ChannelCustomData>(
    channel request: ChatChannelRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatChannel<Custom>, Error>) -> Void)?
  ) {
    spaceInterface.createSpace(
      spaceId: request.channel.id,
      name: request.channel.name,
      type: request.channel.type,
      status: request.channel.status,
      description: request.channel.details,
      custom: request.channel.custom,
      includeCustom: request.includeCustom,
      requestConfig: .init(customConfiguration: request.config)
    ) { result in
      completion?(result.map { ChatChannel(pubnub: $0) })
    }
  }

  public func update<Custom: ChannelCustomData>(
    channel request: ChatChannelRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatChannel<Custom>, Error>) -> Void)?
  ) {
    spaceInterface.updateSpace(
      spaceId: request.channel.id,
      name: request.channel.name,
      type: request.channel.type,
      status: request.channel.status,
      description: request.channel.details,
      custom: request.channel.custom,
      includeCustom: request.includeCustom,
      requestConfig: .init(customConfiguration: request.config)
    ) { result in
      completion?(result.map { ChatChannel(pubnub: $0) })
    }
  }
  
  public func remove<Custom: ChannelCustomData>(
    channel request: ChatChannelRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    spaceInterface.removeSpace(
      spaceId: request.channel.id,
      requestConfig: .init(customConfiguration: request.config),
      completion: completion
    )
  }
}

// MARK: - Requests

public typealias ChannelsFetchRequest = FetchEntitiesRequest<PubNub.SpaceSort>

public struct ChatChannelRequest<Custom: ChannelCustomData>: Equatable {
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
