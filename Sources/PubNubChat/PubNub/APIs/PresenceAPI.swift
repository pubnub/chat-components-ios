//
//  PresenceAPI.swift
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

import PubNub

public protocol PresenceAPI {
  func fetch<Custom: ChatCustomData>(
    hereNow request: FetchHereNowRequest,
    into: Custom.Type,
    completion: ((Result<(occupancy: [String: Int], memberships: [ChatMember<Custom>]), Error>) -> Void)?
  )
  func fetch<Custom: ChatCustomData>(
    presenceState request: FetchPresenceStateRequest,
    into: Custom.Type,
    completion: ((Result<[ChatMember<Custom>], Error>) -> Void)?
  )
  func set<Custom: ChatCustomData>(
    presenceState request: SetPresenceStateRequest,
    into: Custom.Type,
    completion: ((Result<[ChatMember<Custom>], Error>) -> Void)?
  )
}

// MARK: - PubNub Ext

extension PubNub: PresenceAPI {
  public func fetch<Custom: ChatCustomData>(
    hereNow request: FetchHereNowRequest,
    into: Custom.Type = Custom.self,
    completion: ((Result<(occupancy: [String: Int], memberships: [ChatMember<Custom>]), Error>) -> Void)?
  ) {
    hereNow(
      on: request.channels,
      and: request.groups,
      includeUUIDs: request.includeUUIDs,
      includeState: request.includeState,
      custom: .init(customConfiguration: request.config?.mergeChatConsumerID())
    ) { result in
      switch result {
      case .success(let presenceByChannelId):
        let occupancy = presenceByChannelId
          .mapValues { $0.occupancy }

        let memberships = presenceByChannelId
          .flatMap {
            ChatMember<Custom>.presenceMemberships(channelId: $0, presence: $1)
          }

        completion?(.success((occupancy: occupancy, memberships: memberships)))
      case .failure(let error):
        completion?(.failure(error))
      }
    }
  }

  public func fetch<Custom: ChatCustomData>(
    presenceState request: FetchPresenceStateRequest,
    into: Custom.Type = Custom.self,
    completion: ((Result<[ChatMember<Custom>], Error>) -> Void)?
  ) {
    getPresenceState(
      for: request.uuid,
      on: request.channels,
      and: request.groups,
         custom: .init(customConfiguration: request.config?.mergeChatConsumerID())
    ) { result in
      switch result {
      case .success((let memberId, let stateByChannel)):
        let memberships = stateByChannel
          .map { channelId, state in
            ChatMember<Custom>(
              pubnubChannelId: channelId,
              pubnubUserId: memberId,
              isPresent: true,
              presenceState: state
            )
          }
        
        completion?(.success(memberships))
      case .failure(let error):
        completion?(.failure(error))
      }
    }
  }
  
  public func set<Custom: ChatCustomData>(
    presenceState request: SetPresenceStateRequest,
    into: Custom.Type,
    completion: ((Result<[ChatMember<Custom>], Error>) -> Void)?
  ) {
    setPresence(
      state: request.state.scalarDictionary,
      on: request.channels,
      and: request.groups,
      custom: .init(customConfiguration: request.config?.mergeChatConsumerID())
    ) { result in
      switch result {
      case .success(let state):
        let channelMembers = request.channels.map { ChatMember<Custom>(pubnubChannelId: $0, pubnubUserId: request.currentUserId, presenceState: state) }
        let groupMembers = request.groups.map { ChatMember<Custom>(pubnubChannelId: $0, pubnubUserId: request.currentUserId, presenceState: state) }
        
        completion?(.success(channelMembers + groupMembers))
      case .failure(let error):
        completion?(.failure(error))
      }
    }
  }
}

// MARK: - Requests

public struct FetchHereNowRequest: Equatable {
  public let requestId: String = UUID().uuidString

  public var channels: [String]
  public var groups: [String]
  public var includeUUIDs: Bool
  public var includeState: Bool
  
  public var config: PubNubConfiguration?

  public init(
    channels: [String],
    groups: [String] = [],
    includeUUIDs: Bool = true,
    includeState: Bool = true,
    config: PubNubConfiguration? = nil
  ) {
    self.channels = channels
    self.groups = groups
    self.includeUUIDs = includeUUIDs
    self.includeState = includeState
    self.config = config
  }
}

public struct FetchPresenceStateRequest: Equatable {
  public let requestId: String = UUID().uuidString

  public var uuid: String
  public var channels: [String]
  public var groups: [String]
  
  public var config: PubNubConfiguration?

  public init(
    uuid: String,
    channels: [String],
    groups: [String] = [],
    config: PubNubConfiguration? = nil
  ) {
    self.uuid = uuid
    self.channels = channels
    self.groups = groups
    self.config = config
  }
}

public struct SetPresenceStateRequest: Equatable {
  public let requestId: String = UUID().uuidString
  
  public var currentUserId: String
  public var channels: [String]
  public var groups: [String]
  
  public var state: AnyJSON
  
  public var config: PubNubConfiguration?
  
  public init(
    currentUserId: String,
    channels: [String],
    groups: [String] = [],
    state: AnyJSON,
    config: PubNubConfiguration? = nil
  ) {
    self.currentUserId = currentUserId
    self.channels = channels
    self.groups = groups
    self.state = state
    self.config = config
  }
}

extension AnyJSON {
  var scalarDictionary: [String: JSONCodableScalar] {
    guard let jsonData = self.jsonData,
          let dictionary = try? Constant.jsonDecoder.decode([String: JSONCodableScalarType].self, from: jsonData) else {
            return [:]
          }
    
    return dictionary
  }
}
