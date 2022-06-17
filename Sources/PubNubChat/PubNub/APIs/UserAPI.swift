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
import PubNubUser

// MARK: Protocol API

public protocol PubNubUserAPI {
  func fetch<Custom: UserCustomData>(
    users request: UsersFetchRequest,
    into: Custom.Type,
    completion: @escaping ((Result<(users: [ChatUser<Custom>], next: UsersFetchRequest?), Error>) -> Void)
  )
  
  func fetch<Custom: UserCustomData>(
    user request: ChatUserRequest<Custom>,
    into: Custom.Type,
    completion: @escaping ((Result<ChatUser<Custom>, Error>) -> Void)
  )

  func create<Custom: UserCustomData>(
    user request: ChatUserRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatUser<Custom>, Error>) -> Void)?
  )

  func update<Custom: UserCustomData>(
    user request: ChatUserRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatUser<Custom>, Error>) -> Void)?
  )

  func remove<Custom: UserCustomData>(
    user request: ChatUserRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

// MARK: - PubNub Ext

extension PubNubUserAPI {
  func fetchPublisher<Custom: UserCustomData>(
    users request: UsersFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(users: [ChatUser<Custom>], next: UsersFetchRequest?), Error> {
    return Future { promise in
      fetch(users: request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  
  public func fetchPagesPublisher<Custom: UserCustomData>(
    users request: UsersFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatUser<Custom>], UsersFetchRequest?), PaginationError<UsersFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<UsersFetchRequest, PaginationError<UsersFetchRequest>>(request)
    
    return pagedPublisher
      .flatMap({ request in
        fetchPublisher(users: request, into: customType)
          .mapError { PaginationError<UsersFetchRequest>(request: request, error: $0) }
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

extension PubNubProvider {
  public func fetch<Custom: UserCustomData>(
    users request: UsersFetchRequest,
    into: Custom.Type,
    completion: @escaping ((Result<(users: [ChatUser<Custom>], next: UsersFetchRequest?), Error>) -> Void)
  ) {    
    userInterface.fetchUsers(
      includeCustom: request.includeCustom,
      includeTotalCount: request.includeTotalCount,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      requestConfig: .init(customConfiguration: request.config)
    ) { result in
      completion(result.map { ($0.users.map { ChatUser(pubnub: $0) }, request.next(page: $0.next)) })
    }
  }

  public func fetch<Custom: UserCustomData>(
    user request: ChatUserRequest<Custom>,
    into: Custom.Type,
    completion: @escaping ((Result<ChatUser<Custom>, Error>) -> Void)
  ) {
    userInterface.fetchUser(
      userId: request.user.id,
      includeCustom: request.includeCustom,
      requestConfig: .init(customConfiguration: request.config)
    ) { result in
      completion(result.map { ChatUser(pubnub: $0) })
    }
  }

  public func create<Custom: UserCustomData>(
    user request: ChatUserRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatUser<Custom>, Error>) -> Void)?
  ) {
    userInterface.createUser(
      userId: request.user.id,
      name: request.user.name,
      type: request.user.type,
      status:  request.user.status,
      externalId:  request.user.externalId,
      profileUrl:  request.user.avatarURL,
      email:  request.user.email,
      custom:  request.user.custom,
      includeCustom: request.includeCustom,
      requestConfig: .init(customConfiguration: request.config)
    ) { result in
      completion?(result.map { ChatUser(pubnub: $0) })
    }
  }
  
  public func update<Custom: UserCustomData>(
    user request: ChatUserRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<ChatUser<Custom>, Error>) -> Void)?
  ) {
    userInterface.updateUser(
      userId: request.user.id,
      name: request.user.name,
      type: request.user.type,
      status:  request.user.status,
      externalId:  request.user.externalId,
      profileUrl:  request.user.avatarURL,
      email:  request.user.email,
      custom:  request.user.custom,
      includeCustom: request.includeCustom,
      requestConfig: .init(customConfiguration: request.config)
    ) { result in
      completion?(result.map { ChatUser(pubnub: $0) })
    }
  }

  public func remove<Custom: UserCustomData>(
    user request: ChatUserRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    userInterface.removeUser(
      userId: request.user.id,
      requestConfig: .init(customConfiguration: request.config),
      completion: completion
    )
  }
}

// MARK: - Typealias


// MARK: - Request

public typealias UsersFetchRequest = FetchEntitiesRequest<PubNub.UserSort>

public struct FetchEntitiesRequest<Sort> {
  public let requestId: String = UUID().uuidString

  public var includeCustom: Bool
  public var includeTotalCount: Bool
  public var limit: Int?
  public var filter: String?
  public var sort: [Sort]
  public var page: PubNub.Page?
  
  public var config: PubNubConfiguration?

  public init(
    includeCustom: Bool = true,
    includeTotalCount: Bool = false,
    limit: Int? = 100,
    filter: String? = nil,
    sort: [Sort] = [],
    page: PubNub.Page? = nil,
    config: PubNubConfiguration? = nil
  ) {
    self.includeCustom = includeCustom
    self.includeTotalCount = includeTotalCount
    self.limit = limit
    self.filter = filter
    self.sort = sort
    self.page = page
    self.config = config
  }
  
  func next(page: PubNubHashedPage?) -> FetchEntitiesRequest<Sort>? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = .init(next: page.next, prev: page.prev, totalCount: page.totalCount)
    return request
  }
}

extension FetchEntitiesRequest: Equatable, Hashable where Sort: Hashable {}

public struct ChatUserRequest<Custom: UserCustomData>: Hashable {
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
