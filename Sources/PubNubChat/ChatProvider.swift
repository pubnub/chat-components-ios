//
//  ChatProvider.swift
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

import PubNub

public enum ChatError: Error {
  case notImplemented
  
  case entityCreationError
  case missingRequiredData
  
  case wrongContentType
}

public typealias PubNubChatProvider = ChatProvider<VoidCustomData, PubNubManagedChatEntities>

open class ChatProvider<ModelData, ManagedEntities> where ModelData: ChatCustomData, ManagedEntities: ManagedChatEntities {
  
  enum Error: LocalizedError, CustomStringConvertible {
    case Storage
    
    var description: String {
      return ""
    }
  }
  
  let databaseConfig: DatastoreConfiguration
  let coreDataContainer: CoreDataContainer
  
  public var pubnubConfig: PubNubConfiguration {
    return pubnubProvider.configuration
  }
  public var pubnubProvider: PubNubAPI {
    didSet {
      print("DidSet")
      pubnubProvider.add(dataProvider.pubnubListner)
    }
  }

  lazy public private(set) var dataProvider: ChatDataProvider<ModelData, ManagedEntities> = {
    return ChatDataProvider(provider: self)
  }()

  public init(
    datastoreConfiguration: DatastoreConfiguration = .pubnubDefault,
    pubnubConfiguration: PubNubConfiguration
  ) {
    if pubnubConfiguration.uuid.isEmpty {
      preconditionFailure("The PubNub UUID is empty")
    }
    
    do {
      try Self.storeCached(currentUserId: pubnubConfiguration.uuid)
    } catch {
      preconditionFailure("Could not update the stored SenderID cache")
    }

    self.databaseConfig = datastoreConfiguration
    self.pubnubProvider = PubNub(configuration: pubnubConfiguration.mergeChatConsumerID())

    do {
      if let dbURL = databaseConfig.datastoreURL, let directory = databaseConfig.storageDirectoryURL {
        try directory.createDirectory()
        coreDataContainer = try CoreDataContainer(location: .disk(dbURL: dbURL), flushDataOnLoad: databaseConfig.cleanStorageOnLoad)
        
        PubNub.log.info("DB Created at \(dbURL)")
      } else {
        coreDataContainer = try CoreDataContainer(location: .memory, flushDataOnLoad: databaseConfig.cleanStorageOnLoad)
      }
    } catch {
      preconditionFailure("Failed to initialize the in-memory storage with error: \(error). This is a non-recoverable error.")
    }
  
    // Add default listener
    self.pubnubProvider.add(dataProvider.pubnubListner)
  }
}

// MARK: FRC Provider

extension ChatProvider {
  public func fetchedResultsControllerProvider<T: ManagedEntity>(
    fetchRequest: NSFetchRequest<T>,
    sectionKeyPath: String?,
    cacheName: String?
  ) -> NSFetchedResultsController<T> {
    return NSFetchedResultsController(
      fetchRequest: fetchRequest,
      managedObjectContext: coreDataContainer.viewContext,
      sectionNameKeyPath: sectionKeyPath,
      cacheName: cacheName
    )
  }
}
 
// MARK: Sender Management

extension ChatProvider {
  public static var cachedCurrentUserId: String? {
    return try? KeychainWrapper.readString()
  }
  public static func storeCached(currentUserId: String) throws {
    try KeychainWrapper.storeString(content: currentUserId)
  }
  
  public static func removeCachedCurrentUserId() throws {
    try KeychainWrapper.delete()
  }
  
  public var currentUserId: String {
    return pubnubProvider.configuration.uuid
  }

  public func fetchCurrentUser() throws -> ManagedEntities.User {
    let result = try coreDataContainer.viewContext.fetch(
      ManagedEntities.User.userBy(pubnubId: currentUserId)
    )

    guard let user = result.first else {
      throw ChatError.missingRequiredData
    }
        
    return user
  }
  
  public func fetchManagedEntity(with objectId: NSManagedObjectID) -> NSManagedObject {
    return coreDataContainer.viewContext.object(with: objectId)
  }
  
  public func fetchUser(byObjectId managedId: NSManagedObjectID) throws -> ManagedEntities.User {
    return try coreDataContainer.viewContext.existingObject(with: managedId)
  }
  
  public func fetchChannel(byObjectId managedId: NSManagedObjectID) throws -> ManagedEntities.Channel {
    return try coreDataContainer.viewContext.existingObject(with: managedId)
  }
  
  public func fetchMember(byObjectId managedId: NSManagedObjectID) throws -> ManagedEntities.Member {
    return try coreDataContainer.viewContext.existingObject(with: managedId)
  }
  
  public func fetchMessage(byObjectId managedId: NSManagedObjectID) throws -> ManagedEntities.Message {
    return try coreDataContainer.viewContext.existingObject(with: managedId)
  }
  
  public func fetchChannel(byPubNubId channelId: String) throws -> ManagedEntities.Channel? {
    let request = ManagedEntities.Channel.channelBy(pubnubId: channelId)
    request.relationshipKeyPathsForPrefetching = ["members"]
    
    let result = try coreDataContainer.viewContext.fetch(request)
    
    return result.first
  }
  
  /// Will clear any transient/ephmerial data stored
  public func clearTransientData() {
    coreDataContainer.clearTransientProperties()
  }
}

// MARK: Config

public struct DatastoreConfiguration {

  public var cleanStorageOnLoad: Bool

  public var storageDirectoryURL: URL? {
    didSet { datastoreURL = storageDirectoryURL?.appendingPathComponent(storageUniqueFilename) }
  }
  public var storageUniqueFilename: String {
    didSet { datastoreURL = storageDirectoryURL?.appendingPathComponent(storageUniqueFilename) }
  }
  public var datastoreURL: URL?
  
  public init(
    bundle: Bundle = .pubnubChat,
    dataModelFilename: String = "PubNubChatModel",
    storageDirectlyURL: URL? = nil,
    storageUniqueFilename: String = "default",
    cleanStorageOnLoad: Bool = false
  ) {
    self.cleanStorageOnLoad = cleanStorageOnLoad
    self.storageDirectoryURL = storageDirectlyURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    self.storageUniqueFilename = storageUniqueFilename
    self.datastoreURL = self.storageDirectoryURL?.appendingPathComponent(storageUniqueFilename)
  }
  
  public var persistentStorage: Bool {
    return storageDirectoryURL != nil
  }
  
  public static var pubnubDefault: DatastoreConfiguration {
    return DatastoreConfiguration(
      bundle: .pubnubChat,
      dataModelFilename: "PubNubChatModel",
      storageDirectlyURL: nil,
      storageUniqueFilename: "default",
      cleanStorageOnLoad: false
    )
  }
}
