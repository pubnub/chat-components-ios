// CoreDataMigrationManager.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright �© 2022 PubNub Inc.
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

/// This protocol is designated for each class that can perform migration between next `NSManagedObjectModel` versions
///
/// The migration-specific code is invoked before `CoreDataProvider` loads  its persistent stores.
/// You don't have to provide a concrete implementation of `CoreDataMigrationManager` if you rely on `NSManagedObjectModel` provided in `chat-components-ios` bundle.
/// Provide a concrete implementation when creating a `CoreDataProvider` object only if you use your custom model schema.
public protocol CoreDataMigrationManager {
  @discardableResult
  func migrateIfNeeded() -> Bool
}

extension NSManagedObjectModel {
  var integerValue: Int {
    return Int(versionIdentifiers.first as? String ?? String()) ?? 0
  }
}

class DefaultCoreDataMigrationManager: CoreDataMigrationManager {
  
  private let modelBundle: Bundle
  private let modelURL: URL
  private let persistentStoreLocation: URL
  
  init(
    modelBundle: Bundle,
    modelURL: URL,
    persistentStoreLocation: URL
  ) {
    self.modelBundle = modelBundle
    self.modelURL = modelURL
    self.persistentStoreLocation = persistentStoreLocation
  }
  
  @discardableResult
  func migrateIfNeeded() -> Bool {
    
    guard FileManager.default.fileExists(atPath: persistentStoreLocation.relativePath) else {
      PubNub.log.debug("NSPersistentStore at \(persistentStoreLocation.relativePath) doesn't exist. No need to migrate")
      return false
    }
    
    guard let currentPersistentStoreMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
      ofType: NSSQLiteStoreType,
      at: persistentStoreLocation
    ) else {
      PubNub.log.error("Cannot get metadata from the currently used NSPersistentStore")
      return false
    }
    
    guard let storedModelVersionIdentifiers = currentPersistentStoreMetadata["NSStoreModelVersionIdentifiers"] as? [String] else {
      PubNub.log.error("Cannot read versionIdentifiers from the currently stored NSManagedObjectModel")
      return false
    }
    
    let currentlyStoredModelVersion = Int(storedModelVersionIdentifiers.first ?? String()) ?? 0
    let sortedModelVersions = sortedModelVersionFiles()
    
    guard let persistentStoreModel = sortedModelVersions.first(where: { $0.integerValue == currentlyStoredModelVersion }) else {
      PubNub.log.error("The expected NSManagedObjectModel with version set to \(currentlyStoredModelVersion) could not be found")
      return false
    }
    
    var currentlyProcessedModel = persistentStoreModel
    
    for modelVersion in sortedModelVersions where modelVersion.integerValue > currentlyStoredModelVersion {
      
      // Gets metadata in each loop because the previous migration changed them
      guard let storeMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
        ofType: NSSQLiteStoreType,
        at: persistentStoreLocation
      ) else {
        PubNub.log.error("Cannot get NSPersistentStore metadata")
        return false
      }
      
      if !modelVersion.isConfiguration(
        withName: nil,
        compatibleWithStoreMetadata: storeMetadata
      ) {
        do {
          try autoreleasepool {
            try performMigration(
              from: currentlyProcessedModel,
              to: modelVersion
            )
            currentlyProcessedModel = modelVersion
          }
        } catch {
          PubNub.log.error("Migration failed due to error: \(error)")
          return false
        }
      }
    }
    
    return true
  }
  
  private func sortedModelVersionFiles() -> [NSManagedObjectModel] {
    
    let allVersionFiles = modelBundle.paths(
      forResourcesOfType: "mom",
      inDirectory: modelURL.lastPathComponent
    )
    
    let sortedModels = allVersionFiles.compactMap() {
      NSManagedObjectModel(contentsOf: URL(fileURLWithPath: $0))
    }.sorted() {
      $0.integerValue < $1.integerValue
    }
    
    return sortedModels
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
  
  private func resolveMappingModel(
    between sourceModel: NSManagedObjectModel,
    and destinationModel: NSManagedObjectModel
  ) throws -> NSMappingModel? {
    
    let mappingModel = try NSMappingModel.inferredMappingModel(
      forSourceModel: sourceModel,
      destinationModel: destinationModel
    )
    
    // Picks the correct strategy by checking both model versions.
    // Returns an inferred mapping model if the migration is not needed
    if sourceModel.integerValue == 0 && destinationModel.integerValue == 1 {
      PayloadAlignmentMigration.alter(mappingModel: mappingModel)
    }
    
    return mappingModel
  }
}

class PayloadAlignmentMigration {
  
  static func alter(mappingModel: NSMappingModel) {
    
    let entityMapping = mappingModel.entityMappings.first { $0.sourceEntityName == "PubNubManagedMessage" && $0.destinationEntityName == "PubNubManagedMessage" }!
    entityMapping.entityMigrationPolicyClassName = "PubNubChat.PayloadAlignmentMessageEntityMigration"
    entityMapping.mappingType = .customEntityMappingType
    entityMapping.name = "PubNubManagedMessageToPubNubManagedMessage"
    
    mappingModel.entityMappings.removeAll() { $0.sourceEntityName == "PubNubManagedMessage" && $0.destinationEntityName == "PubNubManagedMessage" }
    mappingModel.entityMappings.append(entityMapping)
    
    let sourcePropertyForTextValue = "content"
    let migrationPolicyTargetSelector = "resolveTextProperty:"
    
    let propertyMapping = entityMapping.attributeMappings!.first { $0.name == "text" }!
    propertyMapping.name = "text"
    propertyMapping.valueExpression = NSExpression(format: "FUNCTION($entityPolicy, %@, $source.%@)", migrationPolicyTargetSelector, sourcePropertyForTextValue)
  }
}

@objc(PayloadAlignmentMessageEntityMigration)
class PayloadAlignmentMessageEntityMigration: NSEntityMigrationPolicy {
  
  @objc func resolveTextProperty(_ content: Data) -> String {
    
    let decodedContent = try? Constant.jsonDecoder.decode(AnyJSON.self, from: content)
    let currentTextValue = decodedContent?["text"]?.stringOptional
    
    return currentTextValue ?? String()
  }
}
