//
//  File 2.swift
//  
//
//  Created by Jakub Guz on 9/19/22.
//

#if canImport(SwiftUI) && DEBUG

import Foundation
import PubNub
import PubNubChat
import CoreData
import Combine

// The idea could be creating a shared class (or something similar) that holds shared data.
// Then it's up to you what data you would like to use in your previews. Please don't treat existing implementation very serious, it's rather a POC 

// MARK: ChatProvider with in-memory storage

public let testChatProvider: PubNubChatProvider = {
  
  let chatProvider = PubNubChatProvider(
    pubnubProvider: PubNub(configuration: PubNubConfiguration(publishKey: "...", subscribeKey: "...", userId: "JG")),
    coreDataProvider: try! CoreDataProvider(location: .memory, flushDataOnLoad: false),
    cacheProvider: UserDefaults.standard
  )
  
  let channel = PubNubChatChannel(
    id: "CHANNEL1",
    name: "Channel 1",
    type: "direct",
    status: "status",
    details: "Channel details",
    avatarURL: URL(string: "https://picsum/photos/200/300"),
    updated: nil,
    eTag: nil,
    custom: VoidCustomData()
  )
  
  let user1 = PubNubChatUser(
    id: "JG",
    name: "JG"
  )
  
  let message = PubNubChatMessage(
    id: "12345",
    text: "Hello, world!!!",
    pubnubUserId: "JG",
    pubnubChannelId: "CHANNEL1"
  )
  
  let membership = PubNubChatMember(
    channelId: "CHANNEL1",
    userId: "JG"
  )
  
  chatProvider.dataProvider.load(users: [user1])
  chatProvider.dataProvider.load(members: [membership])
  chatProvider.dataProvider.load(channels: [channel])
  chatProvider.dataProvider.load(messages: [message], processMessageActions: false)
  
  return chatProvider
  
}()

// MARK: ManagedMessageViewModel conformance

class MyViewModel: ManagedMessageViewModel {
  
  public typealias Entity = PubNubManagedMessage
  public typealias ChannelViewModel = PubNubManagedChannel
  public typealias UserViewModel = PubNubManagedUser
  public typealias MessageActionModel = PubNubManagedMessageAction
  
  public var pubnubId: Timetoken { return 0 }
  public var managedObjectId: NSManagedObjectID { return NSManagedObjectID() }
  
  public func decodedContent<T: Decodable>(from: T.Type) throws -> T {
    return try JSONDecoder().decode(T.self, from: Data())
  }
  
  public var messageContentTypePublisher: AnyPublisher<String, Never> {
    Just("TEXT").eraseToAnyPublisher()
  }
  
  public var messageContentPublisher: AnyPublisher<Data, Never> {
    Just(Data()).eraseToAnyPublisher()
  }
  
  public var messageTextPublisher: AnyPublisher<String, Never> {
    Just(
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore."
    ).eraseToAnyPublisher()
  }
  
  public var messageCustomPublisher: AnyPublisher<Data, Never> {
    Just(Data()).eraseToAnyPublisher()
  }
  
  public var messageDateCreatedPublisher: AnyPublisher<Date, Never> {
    Just(Date()).eraseToAnyPublisher()
  }
  
  public var messageActionsPublisher: AnyPublisher<Set<PubNubManagedMessageAction>, Never> {
    Just(Set<PubNubManagedMessageAction>()).eraseToAnyPublisher()
  }
  
  public var messageActions: Set<PubNubManagedMessageAction> {
    Set<PubNubManagedMessageAction>()
  }
  
  public var userViewModel: PubNubManagedUser {
    
    let user = PubNubManagedUser(context: testChatProvider.coreDataContainer.viewContext)
    user.avatarURL = URL(string: "https://picsum.photos/100/300")
    user.id = "JG"
    user.name = "Jakub Jakub Jakub"
    
    return user
  }
  
  public var text: String {
    String("Text Text Text !!!")
  }
  
  public var channelViewModel: PubNubManagedChannel {
    PubNubManagedChannel()
  }
  
  public var messageActionViewModels: Set<PubNubManagedMessageAction> {
    Set<PubNubManagedMessageAction>()
  }
}

// MARK: ManagedChannelViewModel conformance

class MyChannelViewModel: ManagedChannelViewModel {
  
  typealias Entity = PubNubManagedChannel
  typealias MessageViewModel = PubNubManagedMessage
  
  public var pubnubId: String { return String() }
  public var managedObjectId: NSManagedObjectID { return NSManagedObjectID() }
  
  public var channelNamePublisher: AnyPublisher<String?, Never> {
    Just("Channel name").eraseToAnyPublisher()
  }
  
  public var channelDetailsPublisher: AnyPublisher<String?, Never> {
    Just("Channel details").eraseToAnyPublisher()
  }
  
  public var channelAvatarUrlPublisher: AnyPublisher<URL?, Never> {
    Just(URL(string: "https://picsum.photos/300/400")!).eraseToAnyPublisher()
  }
  
  public var channelTypePublisher: AnyPublisher<String, Never> {
    Just("Default").eraseToAnyPublisher()
  }
  public var channelCustomPublisher: AnyPublisher<Data, Never> {
    Just(Data()).eraseToAnyPublisher()
  }
  
  public var membershipPublisher: AnyPublisher<Set<PubNubManagedMember>, Never> {
    Just(Set<PubNubManagedMember>()).eraseToAnyPublisher()
  }
  
  public var memberCountPublisher: AnyPublisher<Int, Never> {
    Just(5).eraseToAnyPublisher()
  }
  
  public var presentMemberCountPublisher: AnyPublisher<Int, Never> {
    Just(5).eraseToAnyPublisher()
  }
  
  public var messagesPublisher: AnyPublisher<Set<PubNubManagedMessage>, Never> {
    Just(Set<PubNubManagedMessage>()).eraseToAnyPublisher()
  }
  
  public var oldestMessagePublisher: AnyPublisher<PubNubManagedMessage?, Never> {
    Just(nil).eraseToAnyPublisher()
  }
}

#endif
