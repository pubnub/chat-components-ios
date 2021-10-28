//
//  MemberAPI.swift
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

public protocol PubNubMemberAPI {
  func fetch<Custom: ChatCustomData>(
    members request: MemberFetchRequest,
    into: Custom.Type,
    completion: ((Result<(members: [ChatMember<Custom>], next: MemberFetchRequest?), Error>) -> Void)?
  )

  func set<Custom: ChatCustomData>(
    members request: MemberModifyRequest,
    into: Custom.Type,
    completion: ((Result<([ChatMember<Custom>], next: MemberModifyRequest?), Error>) -> Void)?
  )

  func remove<Custom: ChatCustomData>(
    members request: MemberModifyRequest,
    into: Custom.Type,
    completion: ((Result<([ChatMember<Custom>], next: MemberModifyRequest?), Error>) -> Void)?
  )
}

extension PubNubMemberAPI {

  public func fetchPublisher<Custom: ChatCustomData>(
    members request: MemberFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(members: [ChatMember<Custom>], next: MemberFetchRequest?), Error> {
    return Future { promise in
      fetch(members: request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  public func fetchPagesPublisher<Custom: ChatCustomData>(
    members request: MemberFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatMember<Custom>], MemberFetchRequest?), PaginationError<MemberFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<MemberFetchRequest, PaginationError<MemberFetchRequest>>(request)
    
    return pagedPublisher
      .flatMap({ request in
        fetchPublisher(members: request, into: customType)
          .mapError { PaginationError<MemberFetchRequest>(request: request, error: $0) }
      })
      .handleEvents(receiveOutput: { output in
        if let request = output.next {
          pagedPublisher.send(request)
        } else {
          pagedPublisher.send(completion: .finished)
        }
      })
      .map { ($0.members, $0.next) }
      .eraseToAnyPublisher()
  }
}

// MARK: - PubNub Ext

extension PubNub: PubNubMemberAPI {
  public func fetch<Custom: ChatCustomData>(
    members request: MemberFetchRequest,
    into: Custom.Type,
    completion: ((Result<(members: [ChatMember<Custom>], next: MemberFetchRequest?), Error>) -> Void)?
  ) {
    fetchMembers(
      channel: request.channelMetadataId,
      include: request.include,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(
        result
          .map {(
            $0.memberships.compactMap { try? $0.transcode() },
            request.next(page: $0.next)
          )}
      )
    }
  }

  public func set<Custom: ChatCustomData>(
    members request: MemberModifyRequest,
    into: Custom.Type,
    completion: ((Result<([ChatMember<Custom>], next: MemberModifyRequest?), Error>) -> Void)?
  ) {
    setMembers(
      channel: request.channelMetadataId,
      uuids: request.userMembers,
      include: request.include,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(
        result
          .map {(
            $0.memberships.compactMap { try? $0.transcode() },
            request.next(page: $0.next)
          )}
      )
    }
  }

  public func remove<Custom: ChatCustomData>(
    members request: MemberModifyRequest,
    into: Custom.Type,
    completion: ((Result<([ChatMember<Custom>], next: MemberModifyRequest?), Error>) -> Void)?
  ) {
    removeMembers(
      channel: request.channelMetadataId,
      uuids: request.userMembers,
      include: request.include,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion?(
        result
          .map {(
            $0.memberships.compactMap { try? $0.transcode() },
            request.next(page: $0.next)
          )}
      )
    }
  }
}

// MARK: - Requests

public struct MemberFetchRequest {
  public let requestId: String = UUID().uuidString
  public var channelMetadataId: String
  public var include: PubNub.MemberInclude
  public var limit: Int?
  public var sort: [PubNub.MembershipSortField]
  public var filter: String?
  public var page: PubNubHashedPage?
  
  public var config: PubNubConfiguration?

  public init(
    channelMetadataId: String,
    include: PubNub.MemberInclude = .init(customFields: true, uuidFields: true, uuidCustomFields: true),
    filter: String? = nil,
    sort: [PubNub.MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = PubNub.Page(),
    config: PubNubConfiguration? = nil
  ) {
    self.channelMetadataId = channelMetadataId
    self.include = include
    self.filter = filter
    self.sort = sort
    self.limit = limit
    self.page = page
    self.config = config
  }
  
  func next(page: PubNubHashedPage?) -> MemberFetchRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension MemberFetchRequest: Equatable {
  public static func == (lhs: MemberFetchRequest, rhs: MemberFetchRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

public struct MemberModifyRequest {
  public let requestId: String = UUID().uuidString
  public var channelMetadataId: String
  public var userMembers: [PubNubMembershipMetadata]
  public var include: PubNub.MemberInclude
  public var limit: Int?
  public var sort: [PubNub.MembershipSortField]
  public var filter: String?
  public var page: PubNubHashedPage?
  
  public var config: PubNubConfiguration?

  public init(
    channelMetadataId: String,
    userMembers: [PubNubMembershipMetadata],
    include: PubNub.MemberInclude = .init(customFields: true, uuidFields: true, uuidCustomFields: true),
    filter: String? = nil,
    sort: [PubNub.MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = PubNub.Page(),
    config: PubNubConfiguration? = nil
  ) {
    self.channelMetadataId = channelMetadataId
    self.userMembers = userMembers
    self.include = include
    self.filter = filter
    self.sort = sort
    self.limit = limit
    self.page = page
    self.config = config
  }
  
  func next(page: PubNubHashedPage?) -> MemberModifyRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension MemberModifyRequest: Equatable {
  public static func == (lhs: MemberModifyRequest, rhs: MemberModifyRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}
