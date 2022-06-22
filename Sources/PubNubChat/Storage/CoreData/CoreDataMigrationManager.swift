//
//  File.swift
//  
//
//  Created by Jakub Guz on 6/22/22.
//

import Foundation
import CoreData
import PubNub

public protocol CoreDataMigrationManager {
  func migrateIfNeeded()
}

extension NSManagedObjectModel {
  var numberVersionIdentifier: Int {
    return Int(versionIdentifiers.first as? String ?? String()) ?? 0
  }
}

class DefaultCoreDataMigrationManager: CoreDataMigrationManager {
  private let rootModel: NSManagedObjectModel
  private let nextModelVersions: [NSManagedObjectModel]
  private let persistentStoreLocation: CoreDataProvider.StoreLocation
  
  private var storeType: String {
    return persistentStoreLocation.rawValue == NSPersistentStoreDescription.inMemeoryStoreURL ? NSInMemoryStoreType : NSSQLiteStoreType
  }
  
  init(
    bundle: Bundle,
    dataModelFilename: String,
    location: CoreDataProvider.StoreLocation
  ) {
    guard let modelURL = bundle.url(forResource: dataModelFilename, withExtension: "momd") else {
      preconditionFailure("NSManagedObjectModel URL failed for filename in bundle \(bundle)")
    }
    
    var modelArray = bundle.paths(forResourcesOfType: "mom", inDirectory: modelURL.lastPathComponent).compactMap() {
      NSManagedObjectModel(contentsOf: URL(fileURLWithPath: $0))
    }.sorted() {
      $0.numberVersionIdentifier < $1.numberVersionIdentifier
    }
    
    self.rootModel = modelArray.removeFirst()
    self.nextModelVersions = modelArray
    self.persistentStoreLocation = location
  }
  
  func migrateIfNeeded() {
    do {
      for modelVersion in nextModelVersions {
        let storeMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
          ofType: self.storeType,
          at: persistentStoreLocation.rawValue
        )
        if !modelVersion.isConfiguration(
          withName: nil,
          compatibleWithStoreMetadata: storeMetadata
        ) {
          autoreleasepool {
            performMigration(
              from: rootModel,
              to: modelVersion
            )
          }
        }
      }
    } catch {
      PubNub.log.error("Failed to get NSPersistentStoreCoordinator metadata")
    }
  }
  
  private func resolveMappingModel(
    between sourceModel: NSManagedObjectModel,
    and destinationModel: NSManagedObjectModel
  ) -> NSMappingModel? {
    do {
      return try PayloadAlignmentMapper(
        sourceModel: sourceModel,
        destinationModel: destinationModel
      ).mappingModel()
    } catch {
      return nil
    }
  }
  
  private func performMigration(
    from sourceModel: NSManagedObjectModel,
    to destinationModel: NSManagedObjectModel
  ) {
    let temporaryStoreLocation = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    
    guard let mappingModel = resolveMappingModel(between: sourceModel, and: destinationModel) else {
      preconditionFailure("Missing mapping model between \(sourceModel) and \(destinationModel)")
    }
    guard let _ = try? temporaryStoreLocation.createDirectory(withIntermediateDirectories: true) else {
      preconditionFailure("Cannot create temporary directory at \(temporaryStoreLocation)")
    }
    
    let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
    let migratedModelsDestinationURL = temporaryStoreLocation.appendingPathComponent(persistentStoreLocation.rawValue.lastPathComponent)
    
    do {
      try manager.migrateStore(
        from: persistentStoreLocation.rawValue,
        sourceType: self.storeType,
        options: nil,
        with: mappingModel,
        toDestinationURL: migratedModelsDestinationURL,
        destinationType: self.storeType,
        destinationOptions: nil
      )
      try NSPersistentStoreCoordinator(managedObjectModel: destinationModel).replacePersistentStore(
        at: persistentStoreLocation.rawValue,
        destinationOptions: nil,
        withPersistentStoreFrom: migratedModelsDestinationURL,
        sourceOptions: nil,
        ofType: self.storeType
      )
      try FileManager.default.removeItem(
        at: temporaryStoreLocation
      )
    } catch {
      PubNub.log.error("CoreData migration failed: \(error)")
    }
  }
}
