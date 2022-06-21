//
//  MockPubNubAPI.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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

import PubNubChat

import PubNub
import PubNubUser
import PubNubSpace
import PubNubMembership

class PubNubMock: PubNubProvider, PubNubUserInterface, PubNubSpaceInterface, PubNubMembershipInterface {
  var pubnub: PubNub = PubNub(
    configuration: .init(
      publishKey: "mock-pub-key",
      subscribeKey: "mock-sub-key",
      userId: "mock-user-id")
  )
  
  var networkSession: SessionReplaceable {
    pubnub.networkSession
  }

  init() {}

// MARK: - User Interface
  var userInterface: PubNubUserInterface {
    return self
  }
  
  // Fetch Users
  var fetchUsersRequest: ((
    _ includeCustom: Bool,
    _ includeTotalCount: Bool,
    _ filter: String?,
    _ sort: [PubNub.UserSort],
    _ limit: Int?,
    _ page: PubNubHashedPage?,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?
  var fetchUsersResponse: (() -> Result<(users: [PubNubUser], next: PubNubHashedPage?), Error>)?
  
  func fetchUsers(
    includeCustom: Bool = true,
    includeTotalCount: Bool = true,
    filter: String? = nil,
    sort: [PubNub.UserSort] = [],
    limit: Int? = 100,
    page: PubNubHashedPage? = nil,
    requestConfig: PubNub.RequestConfiguration = .init(),
    completion: @escaping ((Result<(users: [PubNubUser], next: PubNubHashedPage?), Error>) -> Void)
  ) {
    fetchUsersRequest?(includeCustom, includeTotalCount, filter, sort, limit, page, requestConfig)
    if let response = fetchUsersResponse?() { completion(response) }
  }
  
  var singleUserResponse: (() -> Result<PubNubUser, Error>)?
  
  // Fetch User
  var fetchUserRequest: ((
    _ userId: String?,
    _ includeCustom: Bool,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?
  
  func fetchUser(
    userId: String?,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping (Result<PubNubUser, Error>) -> Void
  ) {
    fetchUserRequest?(userId, includeCustom, requestConfig)
    if let response = singleUserResponse?() { completion(response) }
  }
  
  // Create User
  var createUserRequest: ((
    _ userId: String?,
    _ name: String?,
    _ type: String?,
    _ status: String?,
    _ externalId: String?,
    _ profileUrl: URL?,
    _ email: String?,
    _ custom: FlatJSONCodable?,
    _ includeCustom: Bool,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?
  
  func createUser(
    userId: String?,
    name: String?,
    type: String?,
    status: String?,
    externalId: String?,
    profileUrl: URL?,
    email: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubUser, Error>) -> Void)?
  ) {
    createUserRequest?(
      userId, name, type, status, externalId, profileUrl, email, custom, includeCustom, requestConfig
    )
    if let response = singleUserResponse?() { completion?(response) }
  }

  var voidResponse: (() -> Result<Void, Error>)?

  // Remove User
  var removeUserRequest: ((
    _ userId: String?,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?

  func removeUser(
    userId: String?,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    removeUserRequest?(userId, requestConfig)
    if let response = voidResponse?() { completion?(response) }
  }

  // MARK: - Space Interface

  var spaceInterface: PubNubSpaceInterface {
    return self
  }

  // Fetch Spaces
  var fetchSpacesRequest: ((
    _ includeCustom: Bool,
    _ includeTotalCount: Bool,
    _ filter: String?,
    _ sort: [PubNub.SpaceSort],
    _ limit: Int?,
    _ page: PubNubHashedPage?,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?
  var fetchSpacesResponse: (() -> Result<(spaces: [PubNubSpace], next: PubNubHashedPage?), Error>)?
  
  func fetchSpaces(
    includeCustom: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.SpaceSort],
    limit: Int?,
    page: PubNubHashedPage?,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(spaces: [PubNubSpace], next: PubNubHashedPage?), Error>) -> Void)
  ) {
    fetchSpacesRequest?(includeCustom, includeTotalCount, filter, sort, limit, page, requestConfig)
    if let response = fetchSpacesResponse?() { completion(response) }
  }

  var singleSpaceResponse: (() -> Result<PubNubSpace, Error>)?
  
  // Fetch User
  var fetchSpaceRequest: ((
    _ spaceId: String?,
    _ includeCustom: Bool,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?
  
  func fetchSpace(
    spaceId: String,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping (Result<PubNubSpace, Error>) -> Void
  ) {
    fetchSpaceRequest?(spaceId, includeCustom, requestConfig)
    if let response = singleSpaceResponse?() { completion(response) }
  }

  // Create User
  var createSpaceRequest: ((
    _ spaceId: String?,
    _ name: String?,
    _ type: String?,
    _ status: String?,
    _ description: String?,
    _ custom: FlatJSONCodable?,
    _ includeCustom: Bool,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?

  func createSpace(
    spaceId: String,
    name: String?,
    type: String?,
    status: String?,
    description: String?,
    custom: FlatJSONCodable?,
    includeCustom: Bool,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<PubNubSpace, Error>) -> Void)?
  ) {
    createSpaceRequest?(
      spaceId, name, type, status, description, custom, includeCustom, requestConfig
    )
    if let response = singleSpaceResponse?() { completion?(response) }
  }

  // Remove User
  var removeSpaceRequest: ((
    _ spaceId: String?,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?

  func removeSpace(
    spaceId: String,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    removeSpaceRequest?(spaceId, requestConfig)
    if let response = voidResponse?() { completion?(response) }
  }

  // MARK: - Membership Interface

  var membershipInterface: PubNubMembershipInterface {
    return self
  }

  // Fetch Memberships
  var fetchMembershipsRequest: ((
    _ id: String?,
    _ includeCustom: Bool,
    _ includeTotalCount: Bool,
    _ filter: String?,
    _ userSort: [PubNub.SpaceMembershipSort],
    _ spaceSort: [PubNub.UserMembershipSort],
    _ limit: Int?,
    _ page: PubNubHashedPage?,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?
  var fetchMembershipsResponse: (() -> Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>)?

  func fetchMemberships(
    userId: String?,
    includeCustom: Bool,
    includeSpaceFields: Bool,
    includeSpaceCustomFields: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.SpaceMembershipSort],
    limit: Int?,
    page: PubNubHashedPage?,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>) -> Void)
  ) {
    fetchMembershipsRequest?(
      userId, includeCustom, includeTotalCount, filter, sort, [], limit, page, requestConfig
    )
    if let response = fetchMembershipsResponse?() { completion(response) }
  }

  func fetchMemberships(
    spaceId: String,
    includeCustom: Bool,
    includeUserFields: Bool,
    includeUserCustomFields: Bool,
    includeTotalCount: Bool,
    filter: String?,
    sort: [PubNub.UserMembershipSort],
    limit: Int?,
    page: PubNubHashedPage?,
    requestConfig: PubNub.RequestConfiguration,
    completion: @escaping ((Result<(memberships: [PubNubMembership], next: PubNubHashedPage?), Error>) -> Void)
  ) {
    fetchMembershipsRequest?(
      spaceId, includeCustom, includeTotalCount, filter, [], sort, limit, page, requestConfig
    )
    if let response = fetchMembershipsResponse?() { completion(response) }
  }

  // Add Memberships
  var addUsersBySpaceMembershipsRequest: ((
    _ users: [PubNubMembership.PartialUser],
    _ spaceId: String,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?
  
  func addMemberships(
    users: [PubNubMembership.PartialUser],
    to spaceId: String,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    addUsersBySpaceMembershipsRequest?(users, spaceId, requestConfig)
    if let response = voidResponse?() { completion?(response) }
  }

  var addSpacesByUserMembershipsRequest: ((
    _ spaces: [PubNubMembership.PartialSpace],
    _ userId: String?,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?

  func addMemberships(
    spaces: [PubNubMembership.PartialSpace],
    to userId: String?,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    addSpacesByUserMembershipsRequest?(spaces, userId, requestConfig)
    if let response = voidResponse?() { completion?(response) }
  }

  // Remove Memberships
  var removeUsersFromSpaceMembershipsRequest: ((
    _ userIds: [String],
    _ spaceId: String,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?

  func removeMemberships(
    userIds: [String],
    from spaceId: String,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    removeUsersFromSpaceMembershipsRequest?(userIds, spaceId, requestConfig)
    if let response = voidResponse?() { completion?(response) }
  }

  var removeSpacesFromUserMembershipsRequest: ((
    _ spaceIds: [String],
    _ userId: String?,
    _ requestConfig: PubNub.RequestConfiguration
  ) -> Void)?

  func removeMemberships(
    spaceIds: [String],
    from userId: String?,
    requestConfig: PubNub.RequestConfiguration,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    removeSpacesFromUserMembershipsRequest?(spaceIds, userId, requestConfig)
    if let response = voidResponse?() { completion?(response) }
  }
}
