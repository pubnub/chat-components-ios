//
//  MembershipAPI.swift
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

public protocol PubNubMembershipAPI {
  func fetch<Custom: ChatCustomData>(
    memberships request: MembershipFetchRequest,
    into: Custom.Type,
    completion: ((Result<(members: [ChatMember<Custom>], next: MembershipFetchRequest?), Error>) -> Void)?
  )

  func set<Custom: ChatCustomData>(
    memberships request: MembershipModifyRequest,
    into: Custom.Type,
    completion: ((Result<([ChatMember<Custom>], next: MembershipModifyRequest?), Error>) -> Void)?
  )

  func remove<Custom: ChatCustomData>(
    memberships request: MembershipModifyRequest,
    into: Custom.Type,
    completion: ((Result<([ChatMember<Custom>], next: MembershipModifyRequest?), Error>) -> Void)?
  )
}

extension PubNubMembershipAPI {
  func fetchPublisher<Custom: ChatCustomData>(
    memberships request: MembershipFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(members: [ChatMember<Custom>], next: MembershipFetchRequest?), Error> {
    return Future { promise in
      fetch(memberships: request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  public func fetchPagesPublisher<Custom: ChatCustomData>(
    memberships request: MembershipFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatMember<Custom>], MembershipFetchRequest?), PaginationError<MembershipFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<MembershipFetchRequest, PaginationError<MembershipFetchRequest>>(request)
    
    return pagedPublisher
      .flatMap({ request in
        fetchPublisher(memberships: request, into: customType)
          .mapError { PaginationError<MembershipFetchRequest>(request: request, error: $0) }
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

extension PubNub: PubNubMembershipAPI {
  public func fetch<Custom: ChatCustomData>(
    memberships request: MembershipFetchRequest,
    into: Custom.Type,
    completion: ((Result<(members: [ChatMember<Custom>], next: MembershipFetchRequest?), Error>) -> Void)?
  ) {
    fetchMemberships(
      uuid: request.userMetadataId,
      include: request.include,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page
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
    memberships request: MembershipModifyRequest,
    into: Custom.Type,
    completion: ((Result<([ChatMember<Custom>], next: MembershipModifyRequest?), Error>) -> Void)?
  ) {
    setMemberships(
      uuid: request.userMetadataId,
      channels: request.channelMembers,
      include: request.include,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page
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
    memberships request: MembershipModifyRequest,
    into: Custom.Type,
    completion: ((Result<([ChatMember<Custom>], next: MembershipModifyRequest?), Error>) -> Void)?
  ) {
    removeMemberships(
      uuid: request.userMetadataId,
      channels: request.channelMembers,
      include: request.include,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page
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

public struct MembershipFetchRequest {
  public let requestId: String = UUID().uuidString

  public var userMetadataId: String
  public var include: PubNub.MembershipInclude
  public var limit: Int?
  public var sort: [PubNub.MembershipSortField]
  public var filter: String?
  public var page: PubNubHashedPage?
  
  public var config: PubNubConfiguration?

  public init(
    userMetadataId: String,
    include: PubNub.MembershipInclude = .init(customFields: true, channelFields: true, channelCustomFields: true),
    filter: String? = nil,
    sort: [PubNub.MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = PubNub.Page(),
    config: PubNubConfiguration? = nil
  ) {
    self.userMetadataId = userMetadataId
    self.include = include
    self.filter = filter
    self.sort = sort
    self.limit = limit
    self.page = page
    self.config = config
  }
  
  func next(page: PubNubHashedPage?) -> MembershipFetchRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension MembershipFetchRequest: Equatable {
  public static func == (lhs: MembershipFetchRequest, rhs: MembershipFetchRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

// MARK: MembershipModifyRequest

public struct MembershipModifyRequest {
  public let requestId: String = UUID().uuidString

  public var userMetadataId: String
  public var channelMembers: [PubNubMembershipMetadata]
  public var include: PubNub.MembershipInclude
  public var limit: Int?
  public var sort: [PubNub.MembershipSortField]
  public var filter: String?
  public var page: PubNubHashedPage?
  
  public var config: PubNubConfiguration?

  public init(
    userMetadataId: String,
    channelMembers: [PubNubMembershipMetadata],
    include: PubNub.MembershipInclude = .init(customFields: true, channelFields: true, channelCustomFields: true),
    filter: String? = nil,
    sort: [PubNub.MembershipSortField] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = PubNub.Page(),
    config: PubNubConfiguration? = nil
  ) {
    self.userMetadataId = userMetadataId
    self.channelMembers = channelMembers
    self.include = include
    self.filter = filter
    self.sort = sort
    self.limit = limit
    self.page = page
    self.config = config
  }
  
  func next(page: PubNubHashedPage?) -> MembershipModifyRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension MembershipModifyRequest: Equatable {
  public static func == (lhs: MembershipModifyRequest, rhs: MembershipModifyRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}
