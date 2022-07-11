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
import Combine

import PubNub
import PubNubUser
import PubNubSpace
import PubNubMembership

// MARK: - Data Provider

public class ChatDataProvider<ModelData, ManagedEntities> where ModelData: ChatCustomData, ManagedEntities: ManagedChatEntities {
 
  var provider: ChatProvider<ModelData, ManagedEntities>
  
  /// Instance of a Core Subscription Listener used when calling ``syncPubnubListeners(coreListener:userListener:spaceListener:membershipListener:)``
  public var coreListener = CoreListener()
  /// Instance of a User Subscription Listener used when calling ``syncPubnubListeners(coreListener:userListener:spaceListener:membershipListener:)``
  public var userListener = PubNubUserListener()
  /// Instance of a Space Subscription Listener used when calling ``syncPubnubListeners(coreListener:userListener:spaceListener:membershipListener:)``
  public var spaceListener = PubNubSpaceListener()
  /// Instance of a Membership Subscription Listener used when calling ``syncPubnubListeners(coreListener:userListener:spaceListener:membershipListener:)``
  public var membershipListener = PubNubMembershipListener()

  let datastoreQueue = DispatchQueue(label: "Datastore Write Queue", qos: .userInitiated)
  var cancellations = Set<AnyCancellable>()
  
  init(provider: ChatProvider<ModelData, ManagedEntities>) {
    self.provider = provider
    
    syncPubnubListeners(
      coreListener: coreListener,
      userListener: userListener,
      spaceListener: spaceListener,
      membershipListener: membershipListener
    )
  }

  // MARK: Load Model Data
  
  public func load(
    channels: [ChatChannel<ModelData.Channel>],
    batchSize: Int = 256,
    batchHandler: (([ChatChannel<ModelData.Channel>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if channels.isEmpty {
      DispatchQueue.main.async { completion?() }
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

      DispatchQueue.main.async { completion?() }
    }
  }
  
  public func load(
    users: [ChatUser<ModelData.User>],
    batchSize: Int = 256,
    batchHandler: (([ChatUser<ModelData.User>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if users.isEmpty {
      DispatchQueue.main.async { completion?() }
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

      DispatchQueue.main.async { completion?() }
    }
  }

  public func load(
    members: [ChatMember<ModelData>],
    forceWrite: Bool = true,
    batchSize: Int = 256,
    batchHandler: (([ChatMember<ModelData>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if members.isEmpty {
      DispatchQueue.main.async { completion?() }
      return
    }
    
    datastoreQueue.async { [weak self] in
      for batch in members.chunked(into: batchSize) {
        if let error = self?.provider.coreDataContainer.syncWrite({ context in
          for item in batch {
            try ManagedEntities.Member.insertOrUpdate(
              member: item, forceWrite: forceWrite, into: context
            )
          }
        }) {
          PubNub.log.error("Error saving member batch \(error)")
          
          DispatchQueue.main.async { batchHandler?(batch, error) }
        } else {
          DispatchQueue.main.async { batchHandler?(batch, nil) }
        }
      }
      
      DispatchQueue.main.async { completion?() }
    }
  }

  public func load(
    messages: [ChatMessage<ModelData>],
    processMessageActions: Bool,
    batchSize: Int = 256,
    batchHandler: (([ChatMessage<ModelData>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if messages.isEmpty {
      DispatchQueue.main.async { completion?() }
      return
    }

    datastoreQueue.async { [weak self] in
      for batch in messages.chunked(into: batchSize) {
        if let error = self?.provider.coreDataContainer.syncWrite({ context in
          for item in batch {
            try ManagedEntities.Message.insertOrUpdate(message: item, prcoessMessageActions: processMessageActions, into: context)
          }
        }) {
          PubNub.log.error("Error saving message batch \(error)")
          
          DispatchQueue.main.async { batchHandler?(batch, error) }
        } else {
          DispatchQueue.main.async { batchHandler?(batch, nil) }
        }
      }

      DispatchQueue.main.async { completion?() }
    }
  }
  
  public func load(
    messageActions: [ChatMessageAction<ModelData>],
    batchSize: Int = 256,
    batchHandler: (([ChatMessageAction<ModelData>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if messageActions.isEmpty {
      DispatchQueue.main.async { completion?() }
      return
    }
    
    datastoreQueue.async { [weak self] in
      for batch in messageActions.chunked(into: batchSize) {
        if let error = self?.provider.coreDataContainer.syncWrite({ context in
          for item in batch {
            try ManagedEntities.MessageAction.insertOrUpdate(messageAction: item, into: context)
          }
        }) {
          PubNub.log.error("Error saving message batch \(error)")
          
          DispatchQueue.main.async { batchHandler?(batch, error) }
        } else {
          DispatchQueue.main.async { batchHandler?(batch, nil) }
        }
      }
      
      DispatchQueue.main.async { completion?() }
    }
  }
  
  // MARK: Patch Model Data
  public func patch(
    user patch: ChatUser<ModelData.User>.Patcher,
    completion: ((Error?) -> Void)? = nil
  ) {
    datastoreQueue.async { [weak self] in
      self?.provider.coreDataContainer.write({ context in
        try ManagedEntities.User.patch(
          usingPatch: patch, into: context
        )
      }, errorHandler: { error in
        PubNub.log.error("Error patching user \(error)")
        
        DispatchQueue.main.async { completion?(error) }
      })
    }
  }

  public func patch(
    channel patch: ChatChannel<ModelData.Channel>.Patcher,
    completion: ((Error?) -> Void)? = nil
  ) {
    datastoreQueue.async { [weak self] in
      self?.provider.coreDataContainer.write({ context in
        try ManagedEntities.Channel.patch(
          usingPatch: patch, into: context
        )
      }, errorHandler: { error in
        PubNub.log.error("Error patching channel \(error)")
        
        DispatchQueue.main.async { completion?(error) }
      })
    }
  }

  public func patch(
    member patch: ChatMember<ModelData>.Patcher,
    completion: ((Error?) -> Void)? = nil
  ) {
    datastoreQueue.async { [weak self] in
      self?.provider.coreDataContainer.write({ context in
        try ManagedEntities.Member.patch(
          usingPatch: patch, into: context
        )
      }, errorHandler: { error in
        PubNub.log.error("Error patching channel \(error)")
        
        DispatchQueue.main.async { completion?(error) }
      })
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

  public func removeStoredMembers(
    members: [ChatMember<ModelData>],
    batchSize: Int = 256,
    batchHandler: (([ChatMember<ModelData>], Error?) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {
    if members.isEmpty {
      DispatchQueue.main.async { completion?() }
      return
    }
    
    datastoreQueue.async { [weak self] in
      for batch in members.chunked(into: batchSize) {
        if let error = self?.provider.coreDataContainer.syncWrite({ context in
          for item in batch {
            ManagedEntities.Member.remove(
              channelId: item.chatChannel.id, userId: item.chatUser.id, from: context
            )
          }
        }) {
          PubNub.log.error("Error saving message batch \(error)")
          
          DispatchQueue.main.async { batchHandler?(batch, error) }
        } else {
          DispatchQueue.main.async { batchHandler?(batch, nil) }
        }
      }
      
      DispatchQueue.main.async { completion?() }
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
  
  public func removeStoredMessageAction(
    messageActionId: String,
    completion: ((Error?) -> Void)? = nil
  ) {
    datastoreQueue.async { [weak self] in
      self?.provider.coreDataContainer.write({ context in
        ManagedEntities.MessageAction.remove(messageActionId: messageActionId, from: context)
        completion?(nil)
      }, errorHandler: { error in
        PubNub.log.error("Error removing message action \(error)")
        
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
          self?.load(messages: [message], processMessageActions: false, completion: {
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
        self?.load(messages: messages, processMessageActions: request.actionsInResponse, completion: {
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
        
        self?.load(messages: messages, processMessageActions: request.actionsInResponse, completion: {
          pageHandler?(messagesById, next, nil)
        })
      }
      .store(in: &cancellations)
  }
  
  // MARK: Message Action API Actions
  
  public func sendRemoteMessageAction(
    _ request: MessageActionSendRequest<ModelData>,
    completion: ((Result<ChatMessageAction<ModelData>, Error>) -> Void)?
  ) {
    provider.pubnubProvider
      .sendMessageAction(request) { [weak self] result in
        switch result {
        case .success(let action):
          PubNub.log.debug("Send Message Success \(action)")
          self?.load(messageActions: [action], completion: {
            completion?(.success(action))
          })
        case .failure(let error):
          PubNub.log.error("Send Message Action Error \(error)")
          completion?(.failure(error))
        }
      }
  }

  public func removeRemoteMessageAction(
    _ request: MessageActionRequest<ModelData>,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    provider.pubnubProvider
      .removeMessageAction(request) { [weak self] result in
        switch result {
        case .success(let action):
          PubNub.log.debug("Send Message Success \(action)")
          self?.removeStoredMessageAction(
            messageActionId: action.id,
            completion: { error in
              if let error = error {
                completion?(.failure(error))
              } else {
                completion?(.success(Void()))
              }
            }
          )
        case .failure(let error):
          PubNub.log.error("Send Message Action Error \(error)")
          completion?(.failure(error))
        }
      }
  }
  
  public func syncRemoteMessageActions(
    _ request: MessageActionFetchRequest,
    completion: ((Result<(actions: [ChatMessageAction<ModelData>], next: MessageActionFetchRequest?), PaginationError<MessageActionFetchRequest>>) -> Void)?
  ) {
    provider.pubnubProvider.fetchMessageActions(
      request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case let .success((actions, next)):
        // Store in DB
        self?.load(messageActions: actions, completion: {
          completion?(.success((actions: actions, next: next)))
        })
      case .failure(let error):
        PubNub.log.error("Sync Remote Message Actions Error \(error)")
        completion?(.failure(PaginationError(request: request, error: error)))
      }
    }
  }
  
  public func syncAllRemoteMessageActions(
    _ request: MessageActionFetchRequest,
    pageHandler: (([ChatMessageAction<ModelData>], MessageActionFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<MessageActionFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchMessageActionsPagesPublisher(request, into: ModelData.self)
      .sink { completionSignal in
        switch completionSignal {
        case .finished:
          completion?(nil)
        case .failure(let error):
          PubNub.log.error("Error sycning all remote message actions \(error.localizedDescription) on request \(error.request)")
          completion?(error)
        }
      } receiveValue: { [weak self] actions, next in
        self?.load(messageActions: actions, completion: {
          pageHandler?(actions, next, nil)
        })
      }
      .store(in: &cancellations)
  }

  // MARK: Channel API Actions
  
  public func syncRemoteChannel(
    _ request: ChatChannelRequest<ModelData.Channel>,
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
  
  public func syncRemoteChannels(
    _ request: ChannelsFetchRequest,
    completion: ((Result<(channels: [ChatChannel<ModelData.Channel>], next: ChannelsFetchRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetch(
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
  
  public func syncRemoteChannelsPaginated(
    _ request: ChannelsFetchRequest,
    pageHandler: (([ChatChannel<ModelData.Channel>], ChannelsFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<ChannelsFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchPagesPublisher(channels: request, into: ModelData.Channel.self)
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
  
  public func createRemoteChannel(
    _ request: ChatChannelRequest<ModelData.Channel>,
    completion: ((Result<ChatChannel<ModelData.Channel>, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.create(
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

  public func updateRemoteChannel(
    _ request: ChatChannelRequest<ModelData.Channel>,
    completion: ((Result<ChatChannel<ModelData.Channel>, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.update(
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
    _ request: ChatChannelRequest<ModelData.Channel>,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    provider.pubnubProvider.remove(
      channel: request,
      into: ModelData.Channel.self
    ) { [weak self] result in
      switch result {
      case .success:
        self?.removeStoredChannel(channelId: request.channel.id) { error in
          if let error = error {
            completion?(.failure(error))
          } else {
            completion?(.success(Void()))
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
    _ request: ChatUserRequest<ModelData.User>,
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
  
  public func syncRemoteUsers(
    _ request: UsersFetchRequest,
    completion: ((Result<(channels: [ChatUser<ModelData.User>], next: UsersFetchRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetch(
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
  
  public func syncRemoteUsersPaginated(
    _ request: UsersFetchRequest,
    pageHandler: (([ChatUser<ModelData.User>], UsersFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<UsersFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchPagesPublisher(users: request, into: ModelData.User.self)
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
  
  public func createRemoteUser(
    _ request: ChatUserRequest<ModelData.User>,
    completion: ((Result<ChatUser<ModelData.User>, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.create(
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
  
  public func updateRemoteUser(
    _ request: ChatUserRequest<ModelData.User>,
    completion: ((Result<ChatUser<ModelData.User>, Error>) -> Void)? = nil
  ) {
    provider.pubnubProvider.update(
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
    _ request: ChatUserRequest<ModelData.User>,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    provider.pubnubProvider.remove(
      user: request,
      into: ModelData.User.self
    ) { [weak self] result in
      switch result {
      case .success:
        self?.removeStoredUser(userId: request.user.id) { error in
          if let error = error {
            completion?(.failure(error))
          } else {
            completion?(.success(Void()))
          }
        }
      case .failure(let error):
        PubNub.log.error("Error removing remote user metadata \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  // MARK: Member API Actions
  
  public func syncRemoteUserMembers(
    _ request: UserMemberFetchRequest,
    completion: ((Result<([ChatMember<ModelData>], next: UserMemberFetchRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetch(
      userMembers: request, into: ModelData.self
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
  
  public func syncRemoteChannelMembers(
    _ request: ChannelMemberFetchRequest,
    completion: ((Result<([ChatMember<ModelData>], next: ChannelMemberFetchRequest?), Error>) -> Void)?
  ) {
    provider.pubnubProvider.fetch(
      channelMembers: request, into: ModelData.self
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
  
  public func syncRemoteUserMembersPagination(
    _ request: UserMemberFetchRequest,
    pageHandler: (([ChatMember<ModelData>], UserMemberFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<UserMemberFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchPagesPublisher(userMembers: request, into: ModelData.self)
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
  
  public func syncRemoteChannelMembersPagination(
    _ request: ChannelMemberFetchRequest,
    pageHandler: (([ChatMember<ModelData>], ChannelMemberFetchRequest?, Error?) -> Void)? = nil,
    completion: ((PaginationError<ChannelMemberFetchRequest>?) -> Void)? = nil
  ) {
    provider.pubnubProvider
      .fetchPagesPublisher(channelMembers: request, into: ModelData.self)
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
  
  public func createRemoteMembers(
    _ request: MembersModifyRequest<ModelData>,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    provider.pubnubProvider.create(
      members: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case .success:
        self?.load(members: request.members, completion: {
          completion?(.success(Void()))
        })
      case .failure(let error):
        PubNub.log.error("Error setting remote member \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func updateRemoteMemberships(
    _ request: MembersModifyRequest<ModelData>,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    provider.pubnubProvider.update(
      members: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case .success:
        self?.load(members: request.members, completion: {
          completion?(.success(Void()))
        })
      case .failure(let error):
        PubNub.log.error("Error setting remote member \(error)")
        completion?(.failure(error))
      }
    }
  }
  
  public func removeRemoteMemberships(
    _ request: MembersModifyRequest<ModelData>,
    completion: ((Result<Void, Error>) -> Void)?
  ) {
    provider.pubnubProvider.remove(
      members: request, into: ModelData.self
    ) { [weak self] result in
      switch result {
      case .success:
        self?.removeStoredMembers(members: request.members, completion: {
          completion?(.success(Void()))
        })
      case .failure(let error):
        PubNub.log.error("Error setting remote member \(error)")
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
