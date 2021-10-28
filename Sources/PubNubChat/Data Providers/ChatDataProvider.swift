//
//  ChatDataProvider.swift
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
import CoreData
import UIKit
import Combine

import PubNub

// MARK: - Data Provider

public class ChatDataProvider<ModelData, ManagedEntities> where ModelData: ChatCustomData, ManagedEntities: ManagedChatEntities {
 
  var provider: ChatProvider<ModelData, ManagedEntities>
  
  public var pubnubListner = SubscriptionListener()

  let datastoreQueue = DispatchQueue(label: "Datastore Write Queue", qos: .userInitiated)
  var cancellations = Set<AnyCancellable>()
  
  init(provider: ChatProvider<ModelData, ManagedEntities>) {
    self.provider = provider
    
    syncPubnubSubscribeListener(pubnubListner)
  }

  // MARK: Load Model Data
  
  public func load(
    channels: [ChatChannel<ModelData.Channel>],
    batchSize: Int = 256,
    batchHandler: (([ChatChannel<ModelData.Channel>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if channels.isEmpty {
      completion?()
      return
    }
    
    datastoreQueue.async { [weak self] in
      for batch in channels.chunked(into: batchSize) {
        if let error = self?.provider.coreDataContainer.syncWrite({ context in
          for item in batch {
            try ManagedEntities.Channel.insertOrUpdate(channel: item, into: context)
          }
        }) {
          PubNub.log.error("Error saving channel batch \(error)")

          DispatchQueue.main.async { batchHandler?(batch, error) }
        } else {
          DispatchQueue.main.async { batchHandler?(batch, nil) }
        }
      }

      completion?()
    }
  }
  
  public func load(
    users: [ChatUser<ModelData.User>],
    batchSize: Int = 256,
    batchHandler: (([ChatUser<ModelData.User>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if users.isEmpty {
      completion?()
      return
    }
    
    datastoreQueue.async { [weak self] in
      for batch in users.chunked(into: batchSize) {
        if let error = self?.provider.coreDataContainer.syncWrite({ context in
          for item in batch {
            try ManagedEntities.User.insertOrUpdate(user: item, into: context)
          }
        }) {
          PubNub.log.error("Error saving user batch \(error)")
          
          DispatchQueue.main.async { batchHandler?(batch, error) }
        } else {
          DispatchQueue.main.async { batchHandler?(batch, nil) }
        }
      }

      completion?()
    }
  }

  public func load(
    members: [ChatMember<ModelData>],
    batchSize: Int = 256,
    batchHandler: (([ChatMember<ModelData>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if members.isEmpty {
      completion?()
      return
    }
    
    datastoreQueue.async { [weak self] in
      for batch in members.chunked(into: batchSize) {
        if let error = self?.provider.coreDataContainer.syncWrite({ context in
          for item in batch {
            try ManagedEntities.Member.insertOrUpdate(member: item, into: context)
          }
        }) {
          PubNub.log.error("Error saving member batch \(error)")
          
          DispatchQueue.main.async { batchHandler?(batch, error) }
        } else {
          DispatchQueue.main.async { batchHandler?(batch, nil) }
        }
      }
      
      completion?()
    }
  }
  
  
  public func load(
    messages: [ChatMessage<ModelData>],
    batchSize: Int = 256,
    batchHandler: (([ChatMessage<ModelData>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if messages.isEmpty {
      completion?()
      return
    }

    datastoreQueue.async { [weak self] in
      for batch in messages.chunked(into: batchSize) {
        if let error = self?.provider.coreDataContainer.syncWrite({ context in
          for item in batch {
            try ManagedEntities.Message.insertOrUpdate(message: item, into: context)
          }
        }) {
          PubNub.log.error("Error saving message batch \(error)")
          
          DispatchQueue.main.async { batchHandler?(batch, error) }
        } else {
          DispatchQueue.main.async { batchHandler?(batch, nil) }
        }
      }

      completion?()
    }
  }
  
  // MARK: Remove Model Data
  
  public func removeStoredChannel(
    channelId: String,
    completion: ((Error?) -> Void)? = nil
  ) {
    datastoreQueue.async { [weak self] in
      self?.provider.coreDataContainer.write({ context in
        ManagedEntities.Channel.remove(channelId: channelId, from: context)
        completion?(nil)
      }, errorHandler: { error in
        PubNub.log.error("Error removing channel \(error)")
        
        DispatchQueue.main.async { completion?(error) }
      })
    }
  }
  
  public func removeStoredUser(
    userId: String,
    completion: ((Error?) -> Void)? = nil
  ) {
    datastoreQueue.async { [weak self] in
      self?.provider.coreDataContainer.write({ context in
        ManagedEntities.User.remove(userId: userId, from: context)
        completion?(nil)
      }, errorHandler: { error in
        PubNub.log.error("Error removing user \(error)")
        
        DispatchQueue.main.async { completion?(error) }
      })
    }
  }
  
  public func removeStoredMember(
    channelId: String,
    userId: String,
    completion: ((Error?) -> Void)? = nil
  ) {
    datastoreQueue.async { [weak self] in
      self?.provider.coreDataContainer.write({ context in
        ManagedEntities.Member.remove(channelId: channelId, userId: userId, from: context)
        completion?(nil)
      }, errorHandler: { error in
        PubNub.log.error("Error removing member \(error)")
        
        DispatchQueue.main.async { completion?(error) }
      })
    }
  }
  
  public func removeStoredMessage(
    messageId: String,
    completion: ((Error?) -> Void)? = nil
  ) {
    datastoreQueue.async { [weak self] in
      self?.provider.coreDataContainer.write({ context in
        ManagedEntities.Message.remove(messageId: messageId, from: context)
        completion?(nil)
      }, errorHandler: { error in
        PubNub.log.error("Error removing message \(error)")
        
        DispatchQueue.main.async { completion?(error) }
      })
    }
  }
  
  // MARK: Typing Indicator Service
  
  public func member(
    userId: String,
    didStartTypingOn channelId: String,
    timetoken date: Date?
  ) {
    TypingIndicatorService.shared
      .updateTypingStatus(
        channelId: channelId,
        userId: userId,
        typingStatus: date
      )
  }

  // MARK: - PubNub Remote API Helpers
  
  // MARK: Message API Actions
  
  public func sendRemoteMessage(
    _ request: SendMessageRequest<ModelData>,
    completion: ((Result<ChatMessage<ModelData>, Error>) -> Void)?
  ) {
    provider.pubnubProvider
      .sendMessage(request) { [weak self] result in
        switch result {
        case .success(let message):
          PubNub.log.debug("Send Message Success \(message)")
          self?.load(messages: [message], completion: {
            completion?(.success(message))
          })
        case .failure(let error):
          PubNub.log.error("Send Message Error \(error)")
          completion?(.failure(error))
        }
      }
  }
  
  public func syncRemoteMessages(
    _ request: MessageHistoryRequest,
    completion: ((Result<(messageByChannelId: [String: [ChatMessage<ModelData>]], next: MessageHistoryRequest?), PaginationError<MessageHistoryRequest>>) -> Void)?
  ) {
    provider.pubnubProvider.fetchMessageHistory(
      request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case let .success((messagesByChannel, next)):
        // Get all the message values
        let messages = messagesByChannel.values.flatMap({ $0 })
        // Store in DB
        self?.load(messages: messages, completion: {
          completion?(.success((messageByChannelId: messagesByChannel, next: next)))
        })
      case .failure(let error):
        PubNub.log.error("Sync Remote Messages Error \(error)")
        completion?(.failure(PaginationError(request: request, error: error)))
      }
    }
  }
  
  public func syncAllRemoteMessages(
    _ request: MessageHistoryRequest,
    pageHandler: (([String: [ChatMessage<ModelData>]], MessageHistoryRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<MessageHistoryRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchHistoryPagesPublisher(request, into: ModelData.self)
      .sink { completionSignal in
        switch completionSignal {
        case .finished:
          completion?(nil)
        case .failure(let error):
          PubNub.log.error("Error sycning all remote messages \(error.localizedDescription) on request \(error.request)")
          completion?(error)
        }
      } receiveValue: { [weak self] messagesById, next in
        let messages = messagesById.values.flatMap { $0 }
        
        self?.load(messages: messages, completion: {
          pageHandler?(messagesById, next, nil)
        })
      }
      .store(in: &cancellations)
  }

  // MARK: Channel API Actions
  
  public func syncRemoteChannel(
    _ request: ObjectMetadataIdRequest,
    completion: ((Result<ChatChannel<ModelData.Channel>, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.fetch(
      channel: request,
      into: ModelData.Channel.self
    ) { [weak self] result in
      switch result {
      case .success(let remoteChannel):
        self?.load(channels: [remoteChannel], completion: {
          completion?(.success(remoteChannel))
        })
      case .failure(let error):
        PubNub.log.error("Error syncing remote channels \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func syncAllRemoteChannels(
    _ request: ObjectsFetchRequest,
    completion: ((Result<(channels: [ChatChannel<ModelData.Channel>], next: ObjectsFetchRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetchAll(
      channels: request, into: ModelData.Channel.self) { [weak self] result in
        switch result {
        case .success((let channels, let next)):
          self?.load(channels: channels, completion: {
            completion?(.success((channels, next)))
          })
        case .failure(let error):
          completion?(.failure(error))
        }
      }
  }
  
  public func syncAllRemoteChannelsPaginated(
    _ request: ObjectsFetchRequest,
    pageHandler: (([ChatChannel<ModelData.Channel>], ObjectsFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<ObjectsFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchAllPagesPublisher(channels: request, into: ModelData.Channel.self)
      .sink { completionSignal in
        switch completionSignal {
        case .finished:
          completion?(nil)
        case .failure(let error):
          PubNub.log.error("Error syncing remote channels \(error.localizedDescription) on request \(error.request)")
          completion?(error)
        }
      } receiveValue: { [weak self] channels, next in
        self?.load(channels: channels, completion: {
          pageHandler?(channels, next, nil)
        })
      }
      .store(in: &cancellations)
  }
  
  public func setRemoteChannel(
    _ request: ChannelMetadataRequest<ModelData.Channel>,
    completion: ((Result<ChatChannel<ModelData.Channel>, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.set(
      channel: request,
      into: ModelData.Channel.self
    ) { [weak self] result in
      switch result {
      case .success(let remoteChannel):
        self?.load(channels: [remoteChannel], completion: {
          completion?(.success(remoteChannel))
        })
      case .failure(let error):
        PubNub.log.error("Error setting remote channel metadata error \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func removeRemoteChannel(
    _ request: ObjectRemoveRequest,
    completion: ((Result<String, Error>) -> Void)?
  ) {
    provider.pubnubProvider.remove(channel: request) { [weak self] result in
      switch result {
      case .success:
        self?.removeStoredChannel(channelId: request.metadataId) { error in
          if let error = error {
            completion?(.failure(error))
          } else {
            completion?(.success(request.metadataId))
          }
        }
      case .failure(let error):
        PubNub.log.error("Error removing remote channel \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  // MARK: User API Actions
  
  public func syncRemoteUser(
    _ request: ObjectMetadataIdRequest,
    completion: ((Result<ChatUser<ModelData.User>, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.fetch(
      user: request,
      into: ModelData.User.self
    ) { [weak self] result in
      switch result {
      case .success(let remoteUser):
        self?.load(users: [remoteUser], completion: {
          completion?(.success(remoteUser))
        })
      case .failure(let error):
        PubNub.log.error("Error syncing remote User \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func syncAllRemoteUsers(
    _ request: ObjectsFetchRequest,
    completion: ((Result<(channels: [ChatUser<ModelData.User>], next: ObjectsFetchRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetchAll(
      users: request, into: ModelData.User.self) { [weak self] result in
        switch result {
        case .success((let users, let next)):
          self?.load(users: users, completion: {
            completion?(.success((users, next)))
          })
        case .failure(let error):
          completion?(.failure(error))
        }
      }
  }
  
  public func syncAllRemoteUsersPaginated(
    _ request: ObjectsFetchRequest,
    pageHandler: (([ChatUser<ModelData.User>], ObjectsFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<ObjectsFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchAllPagesPublisher(users: request, into: ModelData.User.self)
      .sink { completionSignal in
        switch completionSignal {
        case .finished:
          completion?(nil)
        case .failure(let error):
          PubNub.log.error("Error sycning all remote users \(error.localizedDescription) on request \(error.request)")
          completion?(error)
        }
      } receiveValue: { [weak self] users, next in
        self?.load(users: users, completion: {
          pageHandler?(users, next, nil)
        })
      }
      .store(in: &cancellations)
  }
  
  public func setRemoteUser(
    _ request: UserMetadataRequest<ModelData.User>,
    completion: ((Result<ChatUser<ModelData.User>, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.set(
      user: request,
      into: ModelData.User.self
    ) { [weak self] result in
      switch result {
      case .success(let remoteUser):
        self?.load(users: [remoteUser], completion: {
          completion?(.success(remoteUser))
        })
      case .failure(let error):
        PubNub.log.error("Error setting remote user metadata \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func removeRemoteUser(
    _ request: ObjectRemoveRequest,
    completion: ((Result<String, Error>) -> Void)?
  ) {
    provider.pubnubProvider.remove(user: request) { [weak self] result in
      switch result {
      case .success:
        self?.removeStoredUser(userId: request.metadataId) { error in
          if let error = error {
            completion?(.failure(error))
          } else {
            completion?(.success(request.metadataId))
          }
        }
      case .failure(let error):
        PubNub.log.error("Error removing remote user metadata \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  // MARK: Member API Actions
  
  public func syncRemoteMember(
    _ request: MemberFetchRequest,
    completion: ((Result<([ChatMember<ModelData>], next: MemberFetchRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetch(
      members: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case let .success((members, next)):
        self?.load(members: members, completion: {
          completion?(.success((members, next: next)))
        })
      case .failure(let error):
        PubNub.log.error("Error syncing remote members \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func syncRemoteMembership(
    _ request: MembershipFetchRequest,
    completion: ((Result<([ChatMember<ModelData>], next: MembershipFetchRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetch(
      memberships: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case let .success((members, next)):
        self?.load(members: members, completion: {
          completion?(.success((members, next: next)))
        })
      case .failure(let error):
        PubNub.log.error("Error fetching remote memberships \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func syncAllRemoteMemberPagination(
    _ request: MemberFetchRequest,
    pageHandler: (([ChatMember<ModelData>], MemberFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<MemberFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchPagesPublisher(members: request, into: ModelData.self)
      .sink { completionSignal in
        switch completionSignal {
        case .finished:
          completion?(nil)
        case .failure(let error):
          PubNub.log.error("Error syncing all remote member \(error.localizedDescription) on request \(error.request)")
          completion?(error)
        }
      } receiveValue: { [weak self] members, next in
        self?.load(members: members, completion: {
          pageHandler?(members, next, nil)
        })
      }
      .store(in: &cancellations)
  }
  
  public func syncAllRemoteMembershipPagination(
    _ request: MembershipFetchRequest,
    pageHandler: (([ChatMember<ModelData>], MembershipFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<MembershipFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchPagesPublisher(memberships: request, into: ModelData.self)
      .sink { completionSignal in
        switch completionSignal {
        case .finished:
          completion?(nil)
        case .failure(let error):
          PubNub.log.error("Error sycning all remote memberships \(error.localizedDescription) on request \(error.request)")
          completion?(error)
        }
      } receiveValue: { [weak self] members, next in
        self?.load(members: members, completion: {
          pageHandler?(members, next, nil)
        })
      }
      .store(in: &cancellations)
  }
  
  public func setRemoteMember(
    _ request: MemberModifyRequest,
    completion: ((Result<([ChatMember<ModelData>], next: MemberModifyRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.set(
      members: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case let .success((members, next)):
        self?.load(members: members, completion: {
          completion?(.success((members, next: next)))
        })
      case .failure(let error):
        PubNub.log.error("Error setting remote member \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func setRemoteMembership(
    _ request: MembershipModifyRequest,
    completion: ((Result<([ChatMember<ModelData>], next: MembershipModifyRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.set(
      memberships: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case let .success((members, next)):
        self?.load(members: members, completion: {
          completion?(.success((members, next: next)))
        })
      case .failure(let error):
        PubNub.log.error("Error setting remote membership \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func removeRemoteMember(
    _ request: MemberModifyRequest,
    completion: ((Result<([ChatMember<ModelData>], next: MemberModifyRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.remove(
      members: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case let .success((members, next)):
        self?.load(members: members, completion: {
          completion?(.success((members, next: next)))
        })
      case .failure(let error):
        PubNub.log.error("Error removing remote member \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func removeRemoteMembership(
    _ request: MembershipModifyRequest,
    completion: ((Result<([ChatMember<ModelData>], next: MembershipModifyRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.remove(
      memberships: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case let .success((members, next)):
        self?.load(members: members, completion: {
          completion?(.success((members, next: next)))
        })
      case .failure(let error):
        PubNub.log.error("Error removing remote membership \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  // MARK: Presence API Actions
  
  public func syncHereNow(
    _ request: FetchHereNowRequest,
    completion: ((Result<(occupancy: [String: Int], members: [ChatMember<ModelData>]), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetch(hereNow: request, into: ModelData.self) { [weak self] result in
      switch result {
      case let .success((occupancy, members)):
        self?.load(members: members, completion: {
          completion?(.success((occupancy, members)))
        })
      case let .failure(error):
        PubNub.log.error("Error syncing HereNow \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func syncRemotePresenceState(
    _ request: FetchPresenceStateRequest,
    completion: ((Result<[ChatMember<ModelData>], Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetch(presenceState: request, into: ModelData.self) { [weak self] result in
      switch result {
      case let .success(members):
        self?.load(members: members, completion: {
          completion?(.success(members))
        })
      case let .failure(error):
        PubNub.log.error("Error syncing remote presence state \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func setRemotePresenceState(
    _ request: SetPresenceStateRequest,
    completion: ((Result<[ChatMember<ModelData>], Error>) -> Void)?
  ) {
    provider.pubnubProvider.set(presenceState: request, into: ModelData.self) { [weak self] result in
      switch result {
      case let .success(members):
        self?.load(members: members, completion: {
          completion?(.success(members))
        })
      case let .failure(error):
        PubNub.log.error("Error setting presence state \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  // MARK: Typing Indicator
  
  public func send(
    isTyping signal: Bool,
    on channelId: String,
    completion: ((Result<Timetoken, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.sendSignal(
      channelId: channelId,
      payload: signal ? TypingIndicatorSignal.typingOn : TypingIndicatorSignal.typingOff,
      completion: completion
    )
  }
}
