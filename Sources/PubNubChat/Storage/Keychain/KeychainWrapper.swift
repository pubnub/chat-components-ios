//
//  KeychainWrapper.swift
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

import PubNub

public struct KeychainDefaults {

  public var suiteName: String?
  public var domain: String
  
  public init(
    suiteName: String?,
    domain: String
  ) {
    self.suiteName = suiteName
    self.domain = domain
  }
  
  public static let standard: KeychainDefaults = {
    return KeychainDefaults(suiteName: nil, domain: "com.pubnub.keychain.service.chat")
  }()
  
  // MARK: - CRUD
  
  public func store<Value: Codable>(_ value: Value, forKey key: String) {
    do {
      try KeychainWrapper.store(
        service: domain,
        accessGroup: suiteName,
        account: key,
        content: value
      )
    } catch {
      PubNub.log.error("Keychain Defaults Error: Could not store value \(value) for key \(key) due to \(error)")
    }
  }
  
  public func read<Value: Codable>(forKey key: String) -> Value? {
    do {
      return try KeychainWrapper.read(
        service: domain,
        accessGroup: suiteName,
        account: key
      )
    } catch {
      PubNub.log.error("Keychain Defaults Error: Could not read value for key \(key) due to \(error)")
      return nil
    }
  }
  
  public func removeValue(forKey key: String) {
    do {
      try KeychainWrapper.delete(service: domain, accessGroup: suiteName, account: key)
    } catch {
      PubNub.log.error("Keychain Defaults Error: Could not remove value for key \(key) due to \(error)")
    }
  }
  
  public func removeAll() {
    do {
      try KeychainWrapper.deleteAll(service: domain, accessGroup: suiteName)
    } catch {
      PubNub.log.error("Keychain Defaults Error: Could not remove all values due to \(error)")
    }
  }
}

// MARK: - Keychain Impl.

struct KeychainWrapper {
  enum KeychainError: Error {
    case dataCodingError
    // Attempted read for an item that does not exist.
    case itemNotFound
    // Attempted save to override an existing item.
    // Use update instead of save to update existing items
    case duplicateItem
    // A read of an item in any format other than Data
    case invalidItemFormat
    // Any operation result status than errSecSuccess
    case unexpectedStatus(OSStatus)
  }

  // MARK: - Create/Update
  
  static func store<Value: Codable>(
    service: String,
    accessGroup: String? = nil,
    account: String,
    content: Value
  ) throws {
    let contentData = try JSONEncoder().encode(content)

    do {
      try save(
        service: service,
        accessGroup: accessGroup,
        account: account,
        contentData: contentData
      )
    } catch KeychainError.duplicateItem {
      try update(
        service: service,
        accessGroup: accessGroup,
        account: account,
        contentData: contentData
      )
    } catch {
      throw error
    }
  }
  
  private static func save(
    service: String,
    accessGroup: String? = nil,
    account: String,
    contentData: Data
  ) throws {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service as Any,
      kSecAttrAccount as String: account as Any,
      kSecValueData as String: contentData as Any
    ]

    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup as Any
    }

    let status = SecItemAdd(
      query as CFDictionary,
      nil
    )

    if status == errSecDuplicateItem {
      throw KeychainError.duplicateItem
    }

    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
  }
  
  private static func update(
    service: String,
    accessGroup: String? = nil,
    account: String,
    contentData: Data
  ) throws {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service as Any,
      kSecAttrAccount as String: account as Any
    ]
    
    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup as Any
    }

    let attributes: [String: AnyObject] = [
      kSecValueData as String: contentData as AnyObject
    ]

    let status = SecItemUpdate(
      query as CFDictionary,
      attributes as CFDictionary
    )

    guard status != errSecItemNotFound else {
      throw KeychainError.itemNotFound
    }

    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
  }
  
  // MARK: - Read
  
  static func read<Value: Codable>(
    service: String,
    accessGroup: String? = nil,
    account: String
  ) throws -> Value? {
    do {
      let content = try read(service: service, accessGroup: accessGroup, account: account)

      return try JSONDecoder().decode(Value.self, from: content)
      
    } catch KeychainError.itemNotFound {
      return nil
    } catch {
      throw error
    }
  }
  
  private static func read(
    service: String,
    accessGroup: String? = nil,
    account: String
  ) throws -> Data {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: true,
      kSecAttrService as String: service as Any,
      kSecAttrAccount as String: account as Any
    ]
    
    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup as Any
    }
    
    var itemCopy: AnyObject?
    let status = SecItemCopyMatching(
      query as CFDictionary,
      &itemCopy
    )
    
    guard status != errSecItemNotFound else {
      throw KeychainError.itemNotFound
    }
    
    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
    
    guard let password = itemCopy as? Data else {
      throw KeychainError.invalidItemFormat
    }
    
    return password
  }
  
  // MARK: - Remove
  
  static func delete(
    service: String,
    accessGroup: String? = nil,
    account: String
  ) throws {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service as Any,
      kSecAttrAccount as String: account as Any
    ]
    
    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup as Any
    }

    let status = SecItemDelete(query as CFDictionary)
    
    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
  }
  
  // MARK: - Remove All
  
  static func deleteAll(
    service: String,
    accessGroup: String? = nil
  ) throws {

    let secClasses = [
      kSecClassGenericPassword,
      kSecClassInternetPassword,
      kSecClassCertificate,
      kSecClassKey,
      kSecClassIdentity
    ]
    
    for secClass in secClasses {
      var query: [String: Any] = [
        kSecClass as String: secClass,
        kSecAttrService as String: service as Any
      ]
      
      if let accessGroup = accessGroup {
        query[kSecAttrAccessGroup as String] = accessGroup as Any
      }
      
      let status = SecItemDelete(query as CFDictionary)
      
      guard status == errSecSuccess else {
        throw KeychainError.unexpectedStatus(status)
      }
    }
  }
}
