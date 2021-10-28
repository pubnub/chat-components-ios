//
//  UserAPI.swift
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

// MARK: Protocol API

public protocol PubNubUserAPI {
  func fetchAll<Custom: UserCustomData>(
    users request: ObjectsFetchRequest,
    into: Custom.Type,
    completion: ((Result<(users: [ChatUser<Custom>], next: ObjectsFetchRequest?), Error>) -> Void)?
  )
  
  func fetch<Custom: UserCustomData>(
    user request: ObjectMetadataIdRequest,
    into: Custom.Type,
    completion: ((Result<ChatUser<Custom>, Error>) -> Void)?
  )

  func set<Custom: UserCustomData>(
    user request: UserMetadataRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatUser<Custom>, Error>) -> Void)?
  )

  func remove(
    user request: ObjectRemoveRequest,
    completion: ((Result<String, Error>) -> Void)?
  )
}

// MARK: - PubNub Ext

extension PubNubUserAPI {
  func fetchAllPublisher<Custom: UserCustomData>(
    users request: ObjectsFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(users: [ChatUser<Custom>], next: ObjectsFetchRequest?), Error> {
    return Future { promise in
      fetchAll(users: request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  
  public func fetchAllPagesPublisher<Custom: UserCustomData>(
    users request: ObjectsFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatUser<Custom>], ObjectsFetchRequest?), PaginationError<ObjectsFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<ObjectsFetchRequest, PaginationError<ObjectsFetchRequest>>(request)
    
    return pagedPublisher
      .flatMap({ request in
        fetchAllPublisher(users: request, into: customType)
          .mapError { PaginationError<ObjectsFetchRequest>(request: request, error: $0) }
      })
      .handleEvents(receiveOutput: { output in
        if let request = output.next {
          pagedPublisher.send(request)
        } else {
          pagedPublisher.send(completion: .finished)
        }
      })
      .map { ($0.users, $0.next) }
      .eraseToAnyPublisher()
  }
}

extension PubNub: PubNubUserAPI {
  
  public func fetchAll<Custom: UserCustomData>(
    users request: ObjectsFetchRequest,
    into: Custom.Type,
    completion: ((Result<(users: [ChatUser<Custom>], next: ObjectsFetchRequest?), Error>) -> Void)?
  ) {
    allUUIDMetadata(
      include: request.include,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(result.map { ($0.uuids.compactMap { try? $0.transcode() }, request.next(page: $0.next)) })
    }
  }

  public func fetch<Custom: UserCustomData>(
    user request: ObjectMetadataIdRequest,
    into: Custom.Type,
    completion: ((Result<ChatUser<Custom>, Error>) -> Void)?
  ) {
    fetch(
      uuid: request.metadataId,
      include: request.includeCustom,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(
        result
          .flatMap { do { return .success(try $0.transcode()) } catch { return .failure(error) } }
      )
    }
  }

  public func set<Custom: UserCustomData>(
    user request: UserMetadataRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatUser<Custom>, Error>) -> Void)?
  ) {
    set(
      uuid: request.user,
      include: request.includeCustom,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(
        result.flatMap { do { return .success(try $0.transcode()) } catch { return .failure(error) } }
      )
    }
  }

  public func remove(
    user request: ObjectRemoveRequest,
    completion: ((Result<String, Error>) -> Void)?
  ) {
    remove(
      uuid: request.metadataId,
      custom: .init(customConfiguration: request.config?.mergeChatConsumerID()),
      completion: completion
    )
  }
}

// MARK: - Typealias


// MARK: - Request

public struct ObjectsFetchRequest {
  public let requestId: String = UUID().uuidString

  public var include: PubNub.IncludeFields
  public var limit: Int?
  public var filter: String?
  public var sort: [PubNub.ObjectSortField]
  public var page: PubNubHashedPage?
  
  public var config: PubNubConfiguration?

  public init(
    include: PubNub.IncludeFields = .init(),
    limit: Int? = 100,
    filter: String? = nil,
    sort: [PubNub.ObjectSortField] = [],
    page: PubNubHashedPage? = PubNub.Page(),
    config: PubNubConfiguration? = nil
  ) {
    self.include = include
    self.limit = limit
    self.filter = filter
    self.sort = sort
    self.page = page
    self.config = config
  }
  
  func next(page: PubNubHashedPage?) -> ObjectsFetchRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension ObjectsFetchRequest: Equatable {
  public static func == (lhs: ObjectsFetchRequest, rhs: ObjectsFetchRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

public struct ObjectMetadataIdRequest: Equatable {
  public let requestId: String = UUID().uuidString

  public var metadataId: String
  public var includeCustom: Bool
  
  public var config: PubNubConfiguration?

  public init(
    metadataId: String,
    includeCustom: Bool = true,
    config: PubNubConfiguration? = nil
  ) {
    self.metadataId = metadataId
    self.includeCustom = includeCustom
    self.config = config
  }
}

public struct UserMetadataRequest<Custom: UserCustomData> {
  public let requestId: String = UUID().uuidString

  public var user: ChatUser<Custom>
  public var includeCustom: Bool
  
  public var config: PubNubConfiguration?

  public init(
    user: ChatUser<Custom>,
    includeCustom: Bool = true,
    config: PubNubConfiguration? = nil
  ) {
    self.user = user
    self.includeCustom = includeCustom
    self.config = config
  }
}

extension UserMetadataRequest: Equatable {
  public static func == (lhs: UserMetadataRequest, rhs: UserMetadataRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

// MARK: - Extensions

extension PubNubUUIDMetadataChangeset {
  func apply<T: PubNubUUIDMetadata>(to object: PubNubUUIDMetadata, into _: T.Type) -> T? {
    return apply(to: object) as? T
  }
}
