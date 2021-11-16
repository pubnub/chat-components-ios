//
//  ChannelViewModel.swift
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
import CoreData
import UIKit

import PubNub
import PubNubChat

// MARK:- Channel

// Rename to Publisher?
public protocol ManagedChannelViewModel {
  associatedtype Entity: ManagedChatChannel
  associatedtype MemberViewModel: ManagedMemberViewModel & Hashable
  associatedtype MessageViewModel: ManagedMessageViewModel & Hashable
  
  var pubnubId: String { get }
  var managedObjectId: NSManagedObjectID { get }
  
  var channelNamePublisher: AnyPublisher<String?, Never> { get }
  var channelDetailsPublisher: AnyPublisher<String?, Never> { get }
  var channelAvatarUrlPublisher: AnyPublisher<URL?, Never> { get }
  var channelTypePublisher: AnyPublisher<String, Never> { get }
  var channelCustomPublisher: AnyPublisher<Data, Never> { get }

  var membershipPublisher: AnyPublisher<Set<MemberViewModel>, Never> { get }
  var memberCountPublisher: AnyPublisher<Int, Never> { get }
  var presentMemberCountPublisher: AnyPublisher<Int, Never> { get }
  
  var messagesPublisher: AnyPublisher<Set<MessageViewModel>, Never> { get }
  var oldestMessagePublisher: AnyPublisher<MessageViewModel?, Never> { get }
}

extension PubNubManagedChannel: ManagedChannelViewModel {
  public typealias Entity = PubNubManagedChannel
  
  public var pubnubId: String { return pubnubChannelID }
  public var managedObjectId: NSManagedObjectID { return objectID }
  
  public var channelNamePublisher: AnyPublisher<String?, Never> {
    return publisher(for: \.name).eraseToAnyPublisher()
  }
  
  public var channelDetailsPublisher: AnyPublisher<String?, Never> {
    return publisher(for: \.details).eraseToAnyPublisher()
  }
  
  public var channelAvatarUrlPublisher: AnyPublisher<URL?, Never> {
    return publisher(for: \.avatarURL).eraseToAnyPublisher()
  }
  
  public var channelTypePublisher: AnyPublisher<String, Never> {
    return publisher(for: \.type).eraseToAnyPublisher()
  }
  public var channelCustomPublisher: AnyPublisher<Data, Never> {
    return publisher(for: \.custom).eraseToAnyPublisher()
  }
  
  public var membershipPublisher: AnyPublisher<Set<PubNubManagedMember>, Never> {
    return publisher(for: \.members).eraseToAnyPublisher()
  }
  
  public var memberCountPublisher: AnyPublisher<Int, Never> {
    return publisher(for: \.memberCount).eraseToAnyPublisher()
  }

  public var presentMemberCountPublisher: AnyPublisher<Int, Never> {
    return publisher(for: \.members)
      .map { $0.filter { $0.isPresent }.count }
      .eraseToAnyPublisher()
  }
  
  public var messagesPublisher: AnyPublisher<Set<MessageViewModel>, Never> {
    return publisher(for: \.messages).eraseToAnyPublisher()
  }
  
  public var oldestMessagePublisher: AnyPublisher<PubNubManagedMessage?, Never> {
    return publisher(for: \.messages)
      .map { $0.min { $0.sortedDate > $1.sortedDate } }
      .eraseToAnyPublisher()
  }
}

// MARK:- User

public protocol ManagedUserViewModel {
  associatedtype Entity: ManagedChatUser

  var pubnubId: String { get }
  var managedObjectId: NSManagedObjectID { get }

  var userName: String? { get }
  var userNamePublisher: AnyPublisher<String?, Never> { get }
  
  var userOccupation: String? { get }
  var userOccupationPublisher: AnyPublisher<String?, Never> { get }
  
  var userAvatarURL: URL? { get }
  var userAvatarUrlPublisher: AnyPublisher<URL?, Never> { get }
}

extension PubNubManagedUser: ManagedUserViewModel {
  public typealias Entity = PubNubManagedUser

  public var pubnubId: String { return pubnubUserID }
  public var managedObjectId: NSManagedObjectID { return objectID }
  
  public var userName: String? {
    return name
  }
  public var userNamePublisher: AnyPublisher<String?, Never> {
    return publisher(for: \.name).eraseToAnyPublisher()
  }
  
  public var userOccupation: String? {
    return occupation
  }
  public var userOccupationPublisher: AnyPublisher<String?, Never> {
    return publisher(for: \.occupation).eraseToAnyPublisher()
  }
  
  public var userAvatarURL: URL? {
    return avatarURL
  }
  public var userAvatarUrlPublisher: AnyPublisher<URL?, Never> {
    return publisher(for: \.avatarURL).eraseToAnyPublisher()
  }
}

// MARK:- Member

public protocol ManagedMemberViewModel {
  associatedtype Entity: ManagedChatMember
  associatedtype ChannelViewModel: ManagedChannelViewModel
  associatedtype UserViewModel: ManagedUserViewModel
  
  var managedObjectId: NSManagedObjectID { get }
  
  var isPresentPublisher: AnyPublisher<Bool, Never> { get }
    
  var channelViewModel: ChannelViewModel { get }
  var userViewModel: UserViewModel { get }
}

extension PubNubManagedMember: ManagedMemberViewModel {
  public typealias Entity = PubNubManagedMember

  public var managedObjectId: NSManagedObjectID { return objectID }
  
  public var isPresentPublisher: AnyPublisher<Bool, Never> {
    return publisher(for: \.isPresent).eraseToAnyPublisher()
  }
  
  public var channelViewModel: PubNubManagedChannel {
    return channel
  }
  
  public var userViewModel: PubNubManagedUser {
    return user
  }
}

// MARK:- Message
 
public protocol ManagedMessageViewModel {
  associatedtype Entity: ManagedChatMessage
  associatedtype ChannelViewModel: ManagedChannelViewModel
  associatedtype UserViewModel: ManagedUserViewModel
  
  var pubnubId: Timetoken { get }
  var managedObjectId: NSManagedObjectID { get }
  
  var messageContentTypePublisher: AnyPublisher<MessageContentType, Never> { get }
  var messageContentPublisher: AnyPublisher<MessageContent, Error> { get }
  
  var messageTextContentPublisher: AnyPublisher<String?, Never> { get }
  var messageLinkContentPublisher: AnyPublisher<URL?, Never> { get }
  var messageImageContentPublisher: AnyPublisher<URL?, Never> { get }
  var messageJSONContentPublisher: AnyPublisher<AnyJSON?, Never> { get }
  
  var messageCustomPublisher: AnyPublisher<Data, Never> { get }
  
  var messageDateCreatedPublisher: AnyPublisher<Date, Never> { get }
  
  var userViewModel: UserViewModel { get }
  var channelViewModel: ChannelViewModel { get }
}

extension PubNubManagedMessage: ManagedMessageViewModel {
  public typealias Entity = PubNubManagedMessage
  
  public var pubnubId: Timetoken { return pubnubMessageID }
  public var managedObjectId: NSManagedObjectID { return objectID }

  public func decodedContent<T: Decodable>(from: T.Type) throws -> T {
    return try JSONDecoder().decode(T.self, from: content)
  }
  
  public var messageContentTypePublisher: AnyPublisher<MessageContentType, Never> {
    return publisher(for: \.contentType)
      .map { MessageContentType(rawValue: $0) }
      .eraseToAnyPublisher()
  }
  
  public var messageContentPublisher: AnyPublisher<MessageContent, Error> {
    return publisher(for: \.content)
      .decode(type: MessageContent.self, decoder: Constant.jsonDecoder)
      .eraseToAnyPublisher()
  }

  public var messageTextContentPublisher: AnyPublisher<String?, Never> {
    return messageContentPublisher
    .map { content -> String? in
      switch content {
      case .text(let content):
        return content
      default:
        return nil
      }
    }
    .replaceError(with: nil)
    .eraseToAnyPublisher()
  }
  public var messageLinkContentPublisher: AnyPublisher<URL?, Never> {
    return messageContentPublisher
      .map { content -> URL? in
        switch content {
        case .link(let content):
          return content
        default:
          return nil
        }
      }
      .replaceError(with: nil)
      .eraseToAnyPublisher()
  }
  public var messageImageContentPublisher: AnyPublisher<URL?, Never> {
    return messageContentPublisher
      .map { content -> URL? in
        switch content {
        case .imageRemote(let content):
          return content
        default:
          return nil
        }
      }
      .replaceError(with: nil)
      .eraseToAnyPublisher()
  }
  public var messageJSONContentPublisher: AnyPublisher<AnyJSON?, Never> {
    return messageContentPublisher
      .map { content -> AnyJSON? in
        switch content {
        case .custom(let content):
          return content
        default:
          return nil
        }
      }
      .replaceError(with: nil)
      .eraseToAnyPublisher()
  }
  
  public var messageCustomPublisher: AnyPublisher<Data, Never> {
    return publisher(for: \.custom).eraseToAnyPublisher()
  }

  
  public var messageDateCreatedPublisher: AnyPublisher<Date, Never> {
    return publisher(for: \.dateCreated).eraseToAnyPublisher()
  }
  
  public var userViewModel: PubNubManagedUser {
    return author
  }
  
  public var channelViewModel: PubNubManagedChannel {
    return channel
  }
}

// MARK: - Chat View Models

public protocol ChatViewModels {
  associatedtype Channel: ManagedChannelViewModel
  associatedtype User: ManagedUserViewModel
  associatedtype Member: ManagedMemberViewModel
  associatedtype Message: ManagedMessageViewModel
}

extension PubNubManagedChatEntities: ChatViewModels {}

// MARK: - Basic Component View Model

public class BasicComponentViewModel: ObservableObject {
  @Published public var primaryImage: UIImage?
  @Published public var primaryLabel: String?
  @Published public var secondaryLabel: String?
  @Published public var tertiaryLabel: String?
  @Published public var quaternaryLabel: String?
  
  public init(
    primaryImage: UIImage? = nil,
    primaryLabel: String? = nil,
    secondaryLabel: String? = nil,
    tertiaryLabel: String? = nil,
    quaternaryLabel: String? = nil
  ) {
    self.primaryImage = primaryImage
    self.primaryLabel = primaryLabel
    self.secondaryLabel = secondaryLabel
    self.tertiaryLabel = tertiaryLabel
    self.quaternaryLabel = quaternaryLabel
  }
}
