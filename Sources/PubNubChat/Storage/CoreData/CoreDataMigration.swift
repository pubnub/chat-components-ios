//
//  File.swift
//  
//
//  Created by Jakub Guz on 6/22/22.
//

import Foundation
import PubNub
import CoreData

class PayloadAlignmentMapper {
  private let sourceModel: NSManagedObjectModel
  private let destinationModel: NSManagedObjectModel
  private let messageEntityClassName = "PubNubManagedMessage"
  
  init(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) {
    self.sourceModel = sourceModel
    self.destinationModel = destinationModel
  }
  
  func mappingModel() throws -> NSMappingModel {
    guard sourceModel.numberVersionIdentifier == 0 && destinationModel.numberVersionIdentifier == 1 else {
      preconditionFailure("Cannot perform migration due to incompatible versions between \(sourceModel) and \(destinationModel)")
    }
    
    let mappingModel = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    let newMessageEntityMapping = createNewMessageEntityMapping(from: mappingModel)
    
    mappingModel.entityMappings.removeAll(where: { $0.sourceEntityName == messageEntityClassName && $0.destinationEntityName == messageEntityClassName })
    mappingModel.entityMappings?.append(newMessageEntityMapping)
    
    return mappingModel
  }
  
  private func textPropertyMapping() -> NSPropertyMapping {
    let sourcePropertyForTextValue = "content"
    let migrationPolicyTargetSelector = String(validatingUTF8: sel_getName(#selector(PayloadAlignmentCustomMigrationPolicy.resolveTextProperty(_:))))!
    
    let propertyMapping = NSPropertyMapping()
    propertyMapping.name = "text"
    propertyMapping.valueExpression = NSExpression(
      format: "FUNCTION($entityPolicy, %@, $source.%@)",
      migrationPolicyTargetSelector, sourcePropertyForTextValue
    )
    
    return propertyMapping
  }
  
  private func createNewMessageEntityMapping(from mappingModel: NSMappingModel) -> NSEntityMapping {
    let inferredMessageEntityMapping = mappingModel.entityMappings.first(where: {
      $0.sourceEntityName == messageEntityClassName && $0.destinationEntityName == messageEntityClassName
    })!
    
    let newMessageEntityMapping = NSEntityMapping()
    newMessageEntityMapping.sourceEntityName = inferredMessageEntityMapping.sourceEntityName
    newMessageEntityMapping.destinationEntityName = inferredMessageEntityMapping.destinationEntityName
    newMessageEntityMapping.entityMigrationPolicyClassName = PayloadAlignmentCustomMigrationPolicy.self.description()
    newMessageEntityMapping.mappingType = .customEntityMappingType
    newMessageEntityMapping.sourceEntityVersionHash = inferredMessageEntityMapping.sourceEntityVersionHash
    newMessageEntityMapping.destinationEntityVersionHash = inferredMessageEntityMapping.destinationEntityVersionHash
    newMessageEntityMapping.relationshipMappings = inferredMessageEntityMapping.relationshipMappings
    newMessageEntityMapping.sourceExpression = NSExpression(
      format: "FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\" , %@, \"TRUEPREDICATE\"), $manager.sourceContext, NO)",
      messageEntityClassName
    )
    
    let txtPropertyMapping = textPropertyMapping()
    newMessageEntityMapping.attributeMappings = inferredMessageEntityMapping.attributeMappings?.filter() { $0.name != txtPropertyMapping.name }
    newMessageEntityMapping.attributeMappings?.append(txtPropertyMapping)
    
    return newMessageEntityMapping
  }
}

class PayloadAlignmentCustomMigrationPolicy: NSEntityMigrationPolicy {
  override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
    try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
  }
  
  @objc func resolveTextProperty(_ content: Data) -> String {
    let decodedContent = try? Constant.jsonDecoder.decode(AnyJSON.self, from: content)
    let currentTextValue = decodedContent?["text"]?.stringOptional
    
    return currentTextValue ?? String()
  }
}
