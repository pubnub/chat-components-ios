//
//  File.swift
//  
//
//  Created by Jakub Guz on 6/22/22.
//

import Foundation
import CoreData
import PubNub

/// This protocol is designated for each class that can perform migration between next `NSManagedObjectModel` versions
///
/// The migration-specific code is invoked before `CoreDataProvider` loads  its persistent stores.
/// You don't have to provide a concrete implementation of `CoreDataMigrationManager` if you rely on `NSManagedObjectModel` provided in `chat-components-ios` bundle.
/// Provide a concrete implementation when creating a `CoreDataProvider` object only if you use your custom model schema.
public protocol CoreDataMigrationManager {
  func migrateIfNeeded() throws
}

extension NSManagedObjectModel {
  var versionID: Int {
    return Int(versionIdentifiers.first as? String ?? String()) ?? 0
  }
}

class DefaultCoreDataMigrationManager: CoreDataMigrationManager {
  private let rootModel: NSManagedObjectModel
  private let nextModelVersions: [NSManagedObjectModel]
  private let persistentStoreLocation: URL
  
  init(
    rootModel: NSManagedObjectModel,
    nextModelVersions: [NSManagedObjectModel],
    persistentStoreLocation: URL
  ) {
    self.rootModel = rootModel
    self.nextModelVersions = nextModelVersions
    self.persistentStoreLocation = persistentStoreLocation
  }
  
  func migrateIfNeeded() throws {
    guard FileManager.default.fileExists(atPath: persistentStoreLocation.relativePath) else {
      return
    }
    
    for modelVersion in nextModelVersions {
      let storeMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
        ofType: NSSQLiteStoreType,
        at: persistentStoreLocation
      )
      if !modelVersion.isConfiguration(
        withName: nil,
        compatibleWithStoreMetadata: storeMetadata
      ) {
        try autoreleasepool {
          try performMigration(
            from: rootModel,
            to: modelVersion
          )
        }
      }
    }
  }
  
  private func resolveMappingModel(
    between sourceModel: NSManagedObjectModel,
    and destinationModel: NSManagedObjectModel
  ) throws -> NSMappingModel? {
    return try PayloadAlignmentMapper(
      sourceModel: sourceModel,
      destinationModel: destinationModel
    ).mappingModel()
  }
  
  private func performMigration(
    from sourceModel: NSManagedObjectModel,
    to destinationModel: NSManagedObjectModel
  ) throws {
    let temporaryStoreLocation = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    
    guard let mappingModel = try resolveMappingModel(between: sourceModel, and: destinationModel) else {
      preconditionFailure("Missing mapping model between \(sourceModel) and \(destinationModel)")
    }
    guard let _ = try? temporaryStoreLocation.createDirectory(withIntermediateDirectories: true) else {
      preconditionFailure("Cannot create temporary directory at \(temporaryStoreLocation)")
    }
    
    let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
    let migratedModelsDestinationURL = temporaryStoreLocation.appendingPathComponent(persistentStoreLocation.lastPathComponent)
    
    try manager.migrateStore(
      from: persistentStoreLocation,
      sourceType: NSSQLiteStoreType,
      options: nil,
      with: mappingModel,
      toDestinationURL: migratedModelsDestinationURL,
      destinationType: NSSQLiteStoreType,
      destinationOptions: [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
    )
    try NSPersistentStoreCoordinator(managedObjectModel: destinationModel).replacePersistentStore(
      at: persistentStoreLocation,
      destinationOptions: nil,
      withPersistentStoreFrom: migratedModelsDestinationURL,
      sourceOptions: nil,
      ofType: NSSQLiteStoreType
    )
    try FileManager.default.removeItem(
      at: temporaryStoreLocation
    )
  }
}

extension DefaultCoreDataMigrationManager {
  enum ModelVersion: Int {
    case initial = 0
    case payloadAlignment = 1
  }
}
