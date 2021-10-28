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
  
  static let chatService = "com.pubnub.keychain.service.chat"
  static let senderAccount = "com.pubnub.senderId"
  
  static func storeString(
    service: String = chatService,
    account: String = senderAccount,
    content: String
  ) throws {
    do {
      try saveString(
        service: service,
        account: account,
        content: content
      )
    } catch KeychainError.duplicateItem {
      try updateString(
        service: service,
        account: account,
        content: content
      )
    } catch {
      throw error
    }
  }
  
  static func saveString(
    service: String = chatService,
    account: String = senderAccount,
    content: String
  ) throws {
    guard let contentData = content.data(using: .utf8) else {
      throw KeychainError.dataCodingError
    }
    
    try save(service: service, account: account, content: contentData)
  }
  
  static func save(
    service: String = chatService,
    account: String,
    content: Data
  ) throws {
    
    let query: [String: AnyObject] = [
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecClass as String: kSecClassGenericPassword,
      kSecValueData as String: content as AnyObject
    ]

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
  
  static func updateString(
    service: String = chatService,
    account: String = senderAccount,
    content: String
  ) throws {
    guard let contentData = content.data(using: .utf8) else {
      throw KeychainError.dataCodingError
    }
    
    try update(service: service, account: account, content: contentData)
  }
  
  static func update(
    service: String = chatService,
    account: String,
    content: Data
  ) throws {
    let query: [String: AnyObject] = [
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecClass as String: kSecClassGenericPassword
    ]

    let attributes: [String: AnyObject] = [
      kSecValueData as String: content as AnyObject
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
  
  static func readString(
    service: String = chatService,
    account: String = senderAccount
  ) throws -> String? {
    do {
      let content = try read(service: service, account: account)
      
      guard let contentString = String(data: content, encoding: .utf8) else {
        throw KeychainError.dataCodingError
      }
      
      return contentString
    } catch KeychainError.itemNotFound {
      return nil
    } catch {
      throw error
    }
  }
  
  static func read(
    service: String = chatService,
    account: String
  ) throws -> Data {
    let query: [String: AnyObject] = [
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecClass as String: kSecClassGenericPassword,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: kCFBooleanTrue
    ]
    
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
  
  static func delete(
    service: String = chatService,
    account: String = senderAccount
  ) throws {
    let query: [String: AnyObject] = [
      kSecAttrService as String: service as AnyObject,
      kSecAttrAccount as String: account as AnyObject,
      kSecClass as String: kSecClassGenericPassword
    ]

    let status = SecItemDelete(query as CFDictionary)
    
    guard status == errSecSuccess else {
      throw KeychainError.unexpectedStatus(status)
    }
  }
}
