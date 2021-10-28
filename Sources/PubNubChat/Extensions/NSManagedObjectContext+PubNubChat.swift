//
//  NSManagedObjectContext+PubNubChat.swift
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

import CoreData

import PubNub

extension NSManagedObjectContext {
  func performSave() throws {
    PubNub.log.debug("Storage Session Opening: CoreData Context")
    do {
      for managedObject in self.updatedObjects {
        if managedObject.changedValues().isEmpty {
          self.refresh(managedObject, mergeChanges: false)
        }
      }

      if self.hasChanges {
        try self.save()
      } else {
        PubNub.log.debug("CoreData Context: No changes to save.")
      }
      
      PubNub.log.debug("Storage Session Closed Successfully: CoreData Context")
    } catch {
      PubNub.log.error("Storage Session failed to save CoreData data: \(error)")
      throw error
    }
  }
  

  @discardableResult
  func insertNew<ManagedObject: NSManagedObject>(object: (ManagedObject) throws -> Void) throws -> ManagedObject {
    let managedObject = try newObject(ManagedObject.self)

    do {
      try object(managedObject)
      return managedObject
    } catch {
      delete(managedObject)
      throw error
    }
  }
  
  func newObject<ManagedObject: NSManagedObject>(_ into: ManagedObject.Type) throws -> ManagedObject {
    guard let managedObject = NSEntityDescription.insertNewObject(
      forEntityName: ManagedObject.entityName,
      into: self
    ) as? ManagedObject else {
      throw ChatError.entityCreationError
    }
    
    return managedObject
  }
  
  public func existingObject<T: NSManagedObject>(with objectID: NSManagedObjectID) throws -> T {
    let managedObject = try existingObject(with: objectID)

    guard let typedObject = managedObject as? T else {
      throw ChatError.entityCreationError
    }
    
    return typedObject
  }
}
