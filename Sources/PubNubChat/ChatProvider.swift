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

public typealias PubNubChatProvider = ChatProvider<VoidCustomData, PubNubManagedChatEntities>

open class ChatProvider<ModelData, ManagedEntities> where ModelData: ChatCustomData, ManagedEntities: ManagedChatEntities {
  
  public let coreDataContainer: CoreDataProvider

  public var cacheProvider: CacheProvider
  
  public var pubnubConfig: PubNubConfiguration {
    return pubnubProvider.configuration
  }
  public var pubnubProvider: PubNubProvider {
    didSet {
      addDefaultPubNubListeners()
    }
  }

  lazy public private(set) var dataProvider: ChatDataProvider<ModelData, ManagedEntities> = {
    return ChatDataProvider(provider: self)
  }()

  public convenience init(
    pubnubProvider: PubNubProvider,
    datastoreConfiguration: DatastoreConfiguration = .pubnubDefault,
    cacheProvider: CacheProvider = UserDefaults.standard
  ) {
    
    var coreDataProvider: CoreDataProvider
    do {
      if let dbURL = datastoreConfiguration.datastoreURL,
          let directory = datastoreConfiguration.storageDirectoryURL {
        try directory.createDirectory()
        coreDataProvider = try CoreDataProvider(
          location: .disk(dbURL: dbURL),
          flushDataOnLoad: datastoreConfiguration.cleanStorageOnLoad
        )
        
        PubNub.log.info("DB Created at \(dbURL)")
      } else {
        coreDataProvider = try CoreDataProvider(
          location: .memory,
          flushDataOnLoad: datastoreConfiguration.cleanStorageOnLoad
        )
      }
    } catch {
      preconditionFailure("Failed to initialize CoreData with error: \(error). This is a non-recoverable error.")
    }
    
    self.init(
      pubnubProvider: pubnubProvider,
      coreDataProvider: coreDataProvider,
      cacheProvider: cacheProvider
    )
  }
  
  public init(
    pubnubProvider: PubNubProvider,
    coreDataProvider: CoreDataProvider,
    cacheProvider: CacheProvider
  ) {
    
    self.pubnubProvider = pubnubProvider
    // Ensure that the telemetry field is set for Chat Components
    self.pubnubProvider.setConsumer(
      identifier: ENV.frameworkIdentifier,
      value: "\(ENV.frameworkIdentifier)/\(ENV.currentVersion)"
    )
    
    self.coreDataContainer = coreDataProvider

    self.cacheProvider = cacheProvider
    // Update the cache with the current user
    self.cacheProvider.cache(currentUserId: pubnubProvider.configuration.uuid)
    
    // Add default listeners
    addDefaultPubNubListeners()
  }
  
  public func addDefaultPubNubListeners() {
    self.pubnubProvider.add(dataProvider.coreListener)
    self.pubnubProvider.add(dataProvider.userListener)
    self.pubnubProvider.add(dataProvider.spaceListener)
    self.pubnubProvider.add(dataProvider.membershipListener)
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
