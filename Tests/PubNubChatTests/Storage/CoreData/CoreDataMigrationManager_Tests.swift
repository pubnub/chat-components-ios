//
//  CoreDataContainer_Tests.swift
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

import XCTest
@testable import PubNubChat
import CoreData

class CoreDataMigrationManager_Tests: XCTestCase {
  
  private var persistentStoreLocation: URL!
  private var managedObjectModels: [NSManagedObjectModel]!
  private var container: NSPersistentContainer!
    
  override func setUpWithError() throws {
    try super.setUpWithError()
    
    let momdURL = try XCTUnwrap(Bundle.module.url(forResource: "PubNubChatModel", withExtension: "momd"))
    let momFilesURL = Bundle.module.paths(forResourcesOfType: "mom", inDirectory: momdURL.lastPathComponent)
    
    // Loads all available NSManagedObjectModel objects and sort them ascending by version identifier
    // Pick in your test cases any versions you want
    managedObjectModels = try momFilesURL.map() { try XCTUnwrap(NSManagedObjectModel(contentsOf: URL(fileURLWithPath: $0))) }.sorted() { $0.versionID < $1.versionID }
    
    // Creates a temporary location you should use when creating NSPersistentStore instances
    let storageDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    persistentStoreLocation = storageDirectory.appendingPathComponent("default")
    
    try storageDirectory.createDirectory(withIntermediateDirectories: true)
  }
  
  override func tearDownWithError() throws {
    try container?.persistentStoreCoordinator.persistentStores.forEach() { [weak container] in
      try container?.persistentStoreCoordinator.remove($0)
    }
    try super.tearDownWithError()
  }
  
  func testMigrationForPayloadAlignment_MigrationProcessDoesNotThrowAnError() throws {
    setUpTestCoreDataStack(for: managedObjectModels[0])
    
    let location = CoreDataProvider.StoreLocation.disk(dbURL: persistentStoreLocation)
    let payloadAlignmentModelVersion = managedObjectModels[1]
    let migrationManager = DefaultCoreDataMigrationManager(rootModel: managedObjectModels[0], nextModelVersions: [payloadAlignmentModelVersion], persistentStoreLocation: location.rawValue)
    
    XCTAssertNoThrow(try migrationManager.migrateIfNeeded())
  }
    
  func testMigrationForPayloadAlignment_MessageTextIsMigrated() throws {
    setUpTestCoreDataStack(for: managedObjectModels[0])
    
    let firstMessageDate = Date()
    let secondMessageDate = Date().addingTimeInterval(15000)
    
    createAndInsertMessageObject(id: "ID_1", dateCreated: firstMessageDate, content: try XCTUnwrap("{ \"text\": \"Lorem ipsum\" }".data(using: .utf8)))
    createAndInsertMessageObject(id: "ID_2", dateCreated: secondMessageDate, content: try XCTUnwrap("{ \"text\": \"Dolor sit amet\" }".data(using: .utf8)))
    
    try container.viewContext.save()
    
    let payloadAlignmentModelVersion = managedObjectModels[1]
    let location = CoreDataProvider.StoreLocation.disk(dbURL: persistentStoreLocation)
    let migrationManager = DefaultCoreDataMigrationManager(rootModel: managedObjectModels[0], nextModelVersions: [payloadAlignmentModelVersion], persistentStoreLocation: location.rawValue)
    
    try migrationManager.migrateIfNeeded()

    // Reloads the CoreData stack because NSManagedObjectModel version has changed after the migration
    setUpTestCoreDataStack(for: payloadAlignmentModelVersion)
    
    let messages = try XCTUnwrap(container.viewContext.fetch(NSFetchRequest<PubNubManagedMessage>(entityName: "PubNubManagedMessage")))
    let expectedFirstMessage = messages.first(where: { $0.id == "ID_1" })!
    let expectedSecondMessage = messages.last(where: { $0.id == "ID_2" })!
    
    XCTAssertEqual(expectedFirstMessage.id, "ID_1")
    XCTAssertEqual(expectedFirstMessage.text, "Lorem ipsum")
    XCTAssertEqual(expectedFirstMessage.dateCreated, firstMessageDate)

    XCTAssertEqual(expectedSecondMessage.id, "ID_2")
    XCTAssertEqual(expectedSecondMessage.text, "Dolor sit amet")
    XCTAssertEqual(expectedSecondMessage.dateCreated, secondMessageDate)
  }
  
  func testMigrationForPayloadAlignment_MessageOtherThanTextIsStillPreserved() throws {
    setUpTestCoreDataStack(for: managedObjectModels[0])
    
    let date = Date()
    let linkContent = try XCTUnwrap("{ \"link\": \"https://www.pubnub.com\" }".data(using: .utf8))
    
    createAndInsertMessageObject(id: "ID_1", dateCreated: date, content: linkContent)
    
    try container.viewContext.save()
    
    let location = CoreDataProvider.StoreLocation.disk(dbURL: persistentStoreLocation)
    let payloadAlignmentModelVersion = managedObjectModels[1]
    let migrationManager = DefaultCoreDataMigrationManager(rootModel: managedObjectModels[0], nextModelVersions: [payloadAlignmentModelVersion], persistentStoreLocation: location.rawValue)
    
    try migrationManager.migrateIfNeeded()
    
    // Reloads the CoreData stack because NSManagedObjectModel version has changed after the migration
    setUpTestCoreDataStack(for: payloadAlignmentModelVersion)
    
    let messages = try XCTUnwrap(container.viewContext.fetch(NSFetchRequest<PubNubManagedMessage>(entityName: "PubNubManagedMessage")))
    let expectedMessage = messages.first(where: { $0.id == "ID_1" })!
    
    XCTAssertEqual(expectedMessage.id, "ID_1")
    XCTAssertEqual(expectedMessage.text, "")
    XCTAssertEqual(expectedMessage.dateCreated, date)
    XCTAssertEqual(expectedMessage.content, linkContent)
  }
  
  func testMigration_DefaultCoreDataMigrationDoesNotThrowAnErrorForInvalidLocation() throws {
    let malformedLocation = persistentStoreLocation.appendingPathComponent("!@#$")
    let payloadAlignmentModelVersion = managedObjectModels[1]
    let migrationManager = DefaultCoreDataMigrationManager(rootModel: managedObjectModels[0], nextModelVersions: [payloadAlignmentModelVersion], persistentStoreLocation: malformedLocation)

    XCTAssertNoThrow(try migrationManager.migrateIfNeeded())
  }
  
  func testMigration_DefaultCoreDataMigrationWorksForAllModelVersions() throws {
    XCTAssertNoThrow(try CoreDataProvider(bundle: Bundle.module, dataModelFilename: "PubNubChatModel", location: CoreDataProvider.StoreLocation.disk(dbURL: persistentStoreLocation)))
  }
  
  func testMigration_CustomMigrationManagerIsInvoked() throws {
    let expectation = expectation(description: "CustomMigrationManager")
    let location = CoreDataProvider.StoreLocation.disk(dbURL: persistentStoreLocation)
    
    XCTAssertNoThrow(try CoreDataProvider(bundle: Bundle.module, dataModelFilename: "PubNubChatModel", location: location, migrationManager: CustmoMigrationManager(onMigrateIfNeededMethodInvoked: {
      expectation.fulfill()
    })))
    
    wait(for: [expectation], timeout: 0.5)
  }
}

private extension CoreDataMigrationManager_Tests {
  func setUpTestCoreDataStack(for model: NSManagedObjectModel)  {
    container = NSPersistentContainer(name: "PubNubChatModel", managedObjectModel: model)
    
    let storeDescription = NSPersistentStoreDescription()
    storeDescription.type = NSSQLiteStoreType
    storeDescription.url = persistentStoreLocation
    
    container.persistentStoreDescriptions = [storeDescription]
    container.loadPersistentStores(completionHandler: { desc, error in
      debugPrint("Did finish loading persistent stores: \(desc). Error: \(String(describing: error))")
    })
  }
  
  func createAndInsertMessageObject(id: String, dateCreated: Date, content: Data) {
    let message = PubNubManagedMessage(entity: container.managedObjectModel.entitiesByName["PubNubManagedMessage"]!, insertInto: container.viewContext)
    message.id = id
    message.dateCreated = dateCreated
    message.content = content
  }
}

private class CustmoMigrationManager: CoreDataMigrationManager {
  private let migrateIfNeededMethodInvoked: (() -> Void)!
  
  init(onMigrateIfNeededMethodInvoked: @escaping (() -> Void)) {
    self.migrateIfNeededMethodInvoked = onMigrateIfNeededMethodInvoked
  }
  
  func migrateIfNeeded() throws {
    migrateIfNeededMethodInvoked()
  }
}
