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
    userMembers request: UserMemberFetchRequest,
    into: Custom.Type,
    completion: @escaping ((Result<(members: [ChatMember<Custom>], next: UserMemberFetchRequest?), Error>) -> Void)
  )
  
  func fetch<Custom: ChatCustomData>(
    channelMembers request: ChannelMemberFetchRequest,
    into: Custom.Type,
    completion: @escaping ((Result<(members: [ChatMember<Custom>], next: ChannelMemberFetchRequest?), Error>) -> Void)
  )

  func create<Custom: ChatCustomData>(
    members request: MembersModifyRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  )

  func update<Custom: ChatCustomData>(
    members request: MembersModifyRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  )

  func remove<Custom: ChatCustomData>(
    members request: MembersModifyRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  )
}

extension PubNubMemberAPI {

  public func fetchPublisher<Custom: ChatCustomData>(
    userMembers request: UserMemberFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(members: [ChatMember<Custom>], next: UserMemberFetchRequest?), Error> {
    return Future { promise in
      fetch(userMembers: request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  public func fetchPagesPublisher<Custom: ChatCustomData>(
    userMembers request: UserMemberFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatMember<Custom>], UserMemberFetchRequest?), PaginationError<UserMemberFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<UserMemberFetchRequest, PaginationError<UserMemberFetchRequest>>(request)
    
    return pagedPublisher
      .flatMap({ request in
        fetchPublisher(userMembers: request, into: customType)
          .mapError { PaginationError<UserMemberFetchRequest>(request: request, error: $0) }
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
  
  public func fetchPublisher<Custom: ChatCustomData>(
    channelMembers request: ChannelMemberFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(members: [ChatMember<Custom>], next: ChannelMemberFetchRequest?), Error> {
    return Future { promise in
      fetch(channelMembers: request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  public func fetchPagesPublisher<Custom: ChatCustomData>(
    channelMembers request: ChannelMemberFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatMember<Custom>], ChannelMemberFetchRequest?), PaginationError<ChannelMemberFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<ChannelMemberFetchRequest, PaginationError<ChannelMemberFetchRequest>>(request)
    
    return pagedPublisher
      .flatMap({ request in
        fetchPublisher(channelMembers: request, into: customType)
          .mapError { PaginationError<ChannelMemberFetchRequest>(request: request, error: $0) }
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
    userMembers request: UserMemberFetchRequest,
    into: Custom.Type,
    completion: @escaping ((Result<(members: [ChatMember<Custom>], next: UserMemberFetchRequest?), Error>) -> Void)
  ) {
    Membership.fetchMemberships(
      spaceId: request.channelId,
      includeCustom: request.includeCustom,
      includeTotalCount: request.includeTotalCount,
      includeUserFields: request.includeUserFields,
      includeUserCustomFields: request.includeUserFields,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion(result.map { ($0.memberships.map { ChatMember(pubnub: $0) }, request.next(page: $0.next)) })
    }
  }
  
  public func fetch<Custom: ChatCustomData>(
    channelMembers request: ChannelMemberFetchRequest,
    into: Custom.Type,
    completion: @escaping ((Result<(members: [ChatMember<Custom>], next: ChannelMemberFetchRequest?), Error>) -> Void)
  ) {
    Membership.fetchMemberships(
      userId: request.userId,
      includeCustom: request.includeCustom,
      includeTotalCount: request.includeTotalCount,
      includeSpaceFields: request.includeChannelFields,
      includeSpaceCustomFields: request.includeChannelFields,
      filter: request.filter,
      sort: request.sort,
      limit: request.limit,
      page: request.page,
      custom: .init(customConfiguration: request.config)
    ) { result in
      completion(result.map { ($0.memberships.map { ChatMember(pubnub: $0) }, request.next(page: $0.next)) })
    }
  }
  
  public func create<Custom: ChatCustomData>(
    members request: MembersModifyRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    // Determine PubNub directionality
    switch(request.membershipPartials) {
    case let (.some(userId), .none, partials):
      // Call the appropriate method
      Membership.addMemberships(
        spaces: partials,
        to: userId,
        custom: .init(customConfiguration: request.config),
        completion: completion
      )
    case let (.none, .some(channelId), partials):
      // Call the appropriate method
      Membership.addMemberships(
        users: partials,
        to: channelId,
        custom: .init(customConfiguration: request.config),
        completion: completion
      )
    default:
      completion?(.failure(ChatError.missingRequiredData))
    }
  }
  
  public func update<Custom: ChatCustomData>(
    members request: MembersModifyRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    // Determine PubNub directionality
    switch(request.membershipPartials) {
    case let (.some(userId), .none, partials):
      // Call the appropriate method
      Membership.updateMemberships(
        spaces: partials,
        on: userId,
        custom: .init(customConfiguration: request.config),
        completion: completion
      )
    case let (.none, .some(channelId), partials):
      // Call the appropriate method
      Membership.updateMemberships(
        users: partials,
        on: channelId,
        custom: .init(customConfiguration: request.config),
        completion: completion
      )
    default:
      completion?(.failure(ChatError.missingRequiredData))
    }
  }
  
  public func remove<Custom: ChatCustomData>(
    members request: MembersModifyRequest<Custom>,
    into: Custom.Type,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    // Determine PubNub directionality
    switch(request.membershipPartials) {
    case let (.some(userId), .none, partials):
      // Call the appropriate method
      Membership.removeMemberships(
        spaceIds: partials.map { $0.id },
        from: userId,
        custom: .init(customConfiguration: request.config),
        completion: completion
      )
    case let (.none, .some(channelId), partials):
      // Call the appropriate method
      Membership.removeMemberships(
        userIds: partials.map { $0.id },
        from: channelId,
        custom: .init(customConfiguration: request.config),
        completion: completion
      )
    default:
      completion?(.failure(ChatError.missingRequiredData))
    }
  }
}

// MARK: - Requests

public struct UserMemberFetchRequest {
  public let requestId: String = UUID().uuidString
  public var channelId: String
  public var includeCustom: Bool
  public var includeTotalCount: Bool
  public var includeUserFields: Bool
  public var limit: Int?
  public var sort: [PubNub.UserMembershipSort]
  public var filter: String?
  public var page: PubNubHashedPage?
  
  public var config: PubNubConfiguration?

  public init(
    channelId: String,
    includeCustom: Bool = true,
    includeTotalCount: Bool = true,
    includeUserFields: Bool = true,
    filter: String? = nil,
    sort: [PubNub.UserMembershipSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    config: PubNubConfiguration? = nil
  ) {
    self.channelId = channelId
    self.includeCustom = includeCustom
    self.includeTotalCount = includeTotalCount
    self.includeUserFields = includeUserFields
    self.filter = filter
    self.sort = sort
    self.limit = limit
    self.page = page
    self.config = config
  }
  
  func next(page: PubNubHashedPage?) -> UserMemberFetchRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension UserMemberFetchRequest: Equatable {
  public static func == (lhs: UserMemberFetchRequest, rhs: UserMemberFetchRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

public struct ChannelMemberFetchRequest {
  public let requestId: String = UUID().uuidString
  public var userId: String
  public var includeCustom: Bool
  public var includeTotalCount: Bool
  public var includeChannelFields: Bool
  public var limit: Int?
  public var sort: [PubNub.SpaceMembershipSort]
  public var filter: String?
  public var page: PubNubHashedPage?
  
  public var config: PubNubConfiguration?
  
  public init(
    userId: String,
    includeCustom: Bool = true,
    includeTotalCount: Bool = true,
    includeChannelFields: Bool = true,
    filter: String? = nil,
    sort: [PubNub.SpaceMembershipSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    config: PubNubConfiguration? = nil
  ) {
    self.userId = userId
    self.includeCustom = includeCustom
    self.includeTotalCount = includeTotalCount
    self.includeChannelFields = includeChannelFields
    self.filter = filter
    self.sort = sort
    self.limit = limit
    self.page = page
    self.config = config
  }
  
  func next(page: PubNubHashedPage?) -> ChannelMemberFetchRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension ChannelMemberFetchRequest: Equatable {
  public static func == (lhs: ChannelMemberFetchRequest, rhs: ChannelMemberFetchRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

public struct MembersModifyRequest<Custom: ChatCustomData> {
  public let requestId: String = UUID().uuidString
  public var members: [ChatMember<Custom>]

  public var config: PubNubConfiguration?

  public init(
    members: [ChatMember<Custom>],
    config: PubNubConfiguration? = nil
  ) {
    self.members = members
    self.config = config
  }
  
  var membershipPartials: (userId: String?, channelId: String?, partials: [PubNubMembership.MembershipPartial]) {
    let channelId = members.first?.pubnubChannelId
    let userId = members.first?.pubnubUserId
    
    if members.first(where: { $0.pubnubChannelId != channelId }) == nil {
      return (userId, nil, members.map { ($0.pubnubChannelId, $0.status, $0.defaultPubnub) })
    } else {
      return (nil, channelId, members.map { ($0.pubnubUserId, $0.status, $0.defaultPubnub) })
    }
  }
}

extension MembersModifyRequest: Equatable {
  public static func == (lhs: MembersModifyRequest, rhs: MembersModifyRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}
