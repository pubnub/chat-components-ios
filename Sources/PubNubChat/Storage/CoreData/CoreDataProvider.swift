//
//  CoreDataContainer.swift
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

public class CoreDataProvider: NSPersistentContainer {
  
  public enum StoreLocation: Equatable, RawRepresentable {
    case memory
    case disk(dbURL: URL)
    
    public init?(rawValue: URL) {
      switch rawValue {
      case NSPersistentStoreDescription.inMemeoryStoreURL:
        self = .memory
      default:
        self = .disk(dbURL: rawValue)
      }
    }
    
    public var rawValue: URL {
      switch self {
      case .memory:
        return NSPersistentStoreDescription.inMemeoryStoreURL
      case .disk(let dbURL):
        return dbURL
      }
    }
  }
  
  public let location: StoreLocation

  // MARK: Init

  public init(
    bundle: Bundle = .pubnubChat,
    dataModelFilename: String = "PubNubChatModel",
    location: StoreLocation,
    flushDataOnLoad: Bool = false,
    clearTransientData: Bool = false,
    migrationManager: CoreDataMigrationManager? = nil
  ) throws {
    guard let modelURL = bundle.url(forResource: dataModelFilename, withExtension: "momd") else {
      preconditionFailure("Managed Object Model URL failed for filename \(dataModelFilename) in bundle \(bundle)")
    }
    guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
      preconditionFailure("Managed Object Model Not Found for filename \(dataModelFilename) in bundle \(bundle)")
    }
    
    self.location = location
    
    super.init(name: dataModelFilename, managedObjectModel: managedObjectModel)
    
    let storeDescription = NSPersistentStoreDescription()
    
    storeDescription.url = location.rawValue
    storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    
    persistentStoreDescriptions = [storeDescription]
    
    if location != StoreLocation.memory {
      if let migrationManager = migrationManager {
        try migrationManager.migrateIfNeeded()
      } else {
        let momFiles = bundle.paths(forResourcesOfType: "mom", inDirectory: modelURL.lastPathComponent)
        var models = momFiles.compactMap() { NSManagedObjectModel(contentsOf: URL(fileURLWithPath: $0)) }.sorted() { $0.versionID < $1.versionID }
        let defaultMigrationManager = DefaultCoreDataMigrationManager(rootModel: models.removeFirst(), nextModelVersions: models, persistentStoreLocation: location.rawValue)
        
        try defaultMigrationManager.migrateIfNeeded()
      }
    }
    
    // Load or Create the Store
    if flushDataOnLoad {
      try recreateDataStore()
    } else {
      try loadPersistentStores()
    }
    
    // Setup View Context (Should this be configurable externally?)
    viewContext.automaticallyMergesChangesFromParent = true
    viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    viewContext.undoManager = nil
    viewContext.shouldDeleteInaccessibleFaults = true

    // Setup Notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(type(of: self).storeRemoteChange(_:)),
      name: .NSPersistentStoreRemoteChange,
      object: self
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(type(of: self).managedObjectContextDidSave(_:)),
      name: .NSManagedObjectContextDidSave,
      object: mutableBackgroundContext
    )

    if clearTransientData {
      clearTransientProperties()
    }
  }
  
  // MARK: Context Types
  
  lazy var mutableBackgroundContext: NSManagedObjectContext = {
    let context = newBackgroundContext()
    context.automaticallyMergesChangesFromParent = true
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    context.undoManager = nil
    context.shouldDeleteInaccessibleFaults = true

    return context
  }()
  
  lazy var readOnlyBackgroundContext: NSManagedObjectContext = {
    let context = newBackgroundContext()
    context.automaticallyMergesChangesFromParent = true
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    context.undoManager = nil
    context.shouldDeleteInaccessibleFaults = true
    
    return context
  }()
  
  private lazy var allContexts: [NSManagedObjectContext] = [viewContext, mutableBackgroundContext, readOnlyBackgroundContext]
  
  // MARK: Store Setup
  
  func loadPersistentStores(setupOnError: Bool = true) throws {
    
    var loadPersistentStoresError: Error?
    var loadedPersistentStoreDescriptions = [String]()
    
    loadPersistentStores { (storeDescription, error) in
      loadPersistentStoresError = error
      loadedPersistentStoreDescriptions.append(storeDescription.description)
    }
    
    if let error = loadPersistentStoresError {
      
      if setupOnError {
        PubNub.log.error("Error loading existing CoreData stores: \(error)")
        
        try recreateDataStore()
      } else {
        throw error
      }
    } else {
      PubNub.log.debug("Loaded store(s): \(loadedPersistentStoreDescriptions)")
    }
  }
  
  func recreateDataStore() throws {
    
    guard let storeDescription = persistentStoreDescriptions.first else {
      preconditionFailure("No persistent store descriptions \(persistentStoreDescriptions)")
    }

    // Remove all existing stores
    try persistentStoreCoordinator.persistentStores.forEach { store in
      do {
        try persistentStoreCoordinator.remove(store)
      } catch {
        PubNub.log.error("Error removing persistent store coordinator \(error)")
        throw error
      }
    }

    // Remove Persistent Store
    if let persistentSQLLiteURL = storeDescription.persistentSQLLiteURL {
      try persistentStoreCoordinator.destroyPersistentStore(at: persistentSQLLiteURL, ofType: NSSQLiteStoreType, options: nil)
      if FileManager.default.fileExists(atPath: persistentSQLLiteURL.absoluteString) {
        try FileManager.default.removeItem(at: persistentSQLLiteURL)
      }
    }
    
    do {
      try loadPersistentStores(setupOnError: false)
    } catch {
      PubNub.log.error("Error loading persistent store \(error)")
    }
  }
  
  // MARK: Writers
  
  func transientWrite(
    _ session: @escaping (NSManagedObjectContext) throws -> Void,
    errorHandler: ((Error) -> Void)? = nil
  ) {
    viewContext.perform { [viewContext] in
      do {
        try autoreleasepool {
          try session(viewContext)
        }
        
        for managedObject in viewContext.updatedObjects {
          if managedObject.changedValues().isEmpty {
            viewContext.refresh(managedObject, mergeChanges: true)
          }
        }
        
        try viewContext.save()
      } catch {
        errorHandler?(error)
      }
    }
  }

  func write(
    // How to pass a context w/o providing all the context methods
    _ session: @escaping (NSManagedObjectContext) throws -> Void,
    errorHandler: ((Error) -> Void)? = nil
  ) {
    mutableBackgroundContext.perform { [mutableBackgroundContext] in
      do {
        try autoreleasepool {
          try session(mutableBackgroundContext)
        }
        try mutableBackgroundContext.performSave()
      } catch {
        errorHandler?(error)
      }
    }
  }
  
  @discardableResult
  func syncWrite(
    _ session: @escaping (NSManagedObjectContext) throws -> Void
  ) -> Error? {
    
    var operationError: Error?
    mutableBackgroundContext.performAndWait { [mutableBackgroundContext] in
      do {
        try autoreleasepool {
          try session(mutableBackgroundContext)
        }
        try mutableBackgroundContext.performSave()
      } catch {
        operationError = error
      }
    }
    
    return operationError
  }

  // MARK: Notifications

  @objc
  func storeRemoteChange(_ notification: Notification) {
    PubNub.log.error("NSPersistentStoreRemoteChange Notification: \(String(describing: notification.userInfo))")
  }
  
  @objc
  func managedObjectContextDidSave(_ notification: Notification) {
    PubNub.log.error("NSManagedObjectContextDidSave Notification: \(String(describing: notification.userInfo))")
  }
}

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}


extension CoreDataProvider: TransientPropertyHolder {
  func clearTransientProperties() {
    mutableBackgroundContext.performAndWait {
      do {
        try self.managedObjectModel.entities.forEach { entityDescription in
          guard let entityName = entityDescription.name else { return }
          let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
          let entities = try mutableBackgroundContext.fetch(fetchRequest) as? [TransientPropertyHolder]
          entities?.forEach { $0.clearTransientProperties() }
        }
        
        if self.mutableBackgroundContext.hasChanges {
          try self.mutableBackgroundContext.save()
        }
        PubNub.log.debug("CoreDataContainer successfully cleared transient properties")
      } catch {
        PubNub.log.error("CoreDataContainer error clearing transient properties: \(error)")
      }
    }
  }
}

// MARK: Hack to start flow work

extension ChatProvider {
  public func resetContext() {
    coreDataContainer.viewContext.reset()
  }
}

extension URL {
  func createDirectory(
    withIntermediateDirectories: Bool = true,
    attributes: [FileAttributeKey : Any]? = nil
  ) throws {
    return try FileManager.default.createDirectory(
      at: self,
      withIntermediateDirectories: withIntermediateDirectories,
      attributes: attributes
    )
  }
}
