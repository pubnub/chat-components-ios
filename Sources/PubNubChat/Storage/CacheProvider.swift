//
//  CacheProvider.swift
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

public protocol CacheProvider {
  func cache(_ string: String, forKey: String)
  func cache(_ int: Int, forKey: String)
  func cache(_ double: Double, forKey: String)
  func cache(_ float: Float, forKey: String)
  func cache(_ url: URL, forKey: String)
  func cache(_ data: Data, forKey: String)
  func cache(_ bool: Bool, forKey: String)

  func string(forKey: String) -> String?
  func integer( forKey: String) -> Int
  func double(forKey: String) -> Double
  func float(forKey: String) -> Float
  func url(forKey: String) -> URL?
  func data(forKey: String) -> Data?
  func bool(forKey: String) -> Bool
  
  func removeCache(forKey: String)
  func clearCache()
}

extension CacheProvider {
  
  // MARK: Helpers
  public func cache<Value: Codable>(_ codable: Value, forKey: String) {
    guard let contentData = try? JSONEncoder().encode(codable) else {
      return
    }
    
    cache(contentData, forKey: forKey)
  }
  
  public func codable<Value: Codable>(forKey: String) -> Value? {
    guard let contentData = data(forKey: forKey) else {
      return nil
    }
    
    return try? JSONDecoder().decode(Value.self, from: contentData)
  }
  
  
  // MARK: Chat Defaults

  public var currentUserId: String? {
    return string(forKey: "com.pubnub.senderId")
  }
  
  public func cache(currentUserId: String) {
    cache(currentUserId, forKey: "com.pubnub.senderId")
  }
  
  public func removeCurrentUserId() {
    removeCache(forKey: "com.pubnub.senderId")
  }
}

// MARK: - User Defaults

extension UserDefaults: CacheProvider {
  
  // MARK: Write
  public func cache(_ string: String, forKey key: String) {
    self.set(string, forKey: key)
  }
  public func cache(_ int: Int, forKey key: String) {
    self.set(int, forKey: key)
  }
  public func cache(_ double: Double, forKey key: String) {
    self.set(double, forKey: key)
  }
  public func cache(_ float: Float, forKey key: String) {
    self.set(float, forKey: key)
  }
  public func cache(_ url: URL, forKey key: String) {
    self.set(url, forKey: key)
  }
  public func cache(_ data: Data, forKey key: String) {
    self.set(data, forKey: key)
  }
  public func cache(_ bool: Bool, forKey key: String) {
    self.set(bool, forKey: key)
  }
  public func cache(_ object: AnyObject, forKey key: String) {
    self.set(object, forKey: key)
  }
  
  // MARK: Remove
  public func removeCache(forKey key: String) {
    self.removeObject(forKey: key)
  }
  
  public func clearCache() {
    self.dictionaryRepresentation().keys.forEach(self.removeObject(forKey:))
  }
}

// MARK: - Keychain Defaults

extension KeychainDefaults: CacheProvider {

  // MARK: Write
  public func cache(_ string: String, forKey key: String) {
    self.store(string, forKey: key)
  }
  public func cache(_ int: Int, forKey key: String) {
    self.store(int, forKey: key)
  }
  public func cache(_ double: Double, forKey key: String) {
    self.store(double, forKey: key)
  }
  public func cache(_ float: Float, forKey key: String) {
    self.store(float, forKey: key)
  }
  public func cache(_ url: URL, forKey key: String) {
    self.store(url, forKey: key)
  }
  public func cache(_ data: Data, forKey key: String) {
    self.store(data, forKey: key)
  }
  public func cache(_ bool: Bool, forKey key: String) {
    self.store(bool, forKey: key)
  }
  
  // MARK: Read
  public func string(forKey key: String) -> String? {
    return self.read(forKey: key)
  }
  
  public func integer(forKey key: String) -> Int {
    return self.read(forKey: key) ?? 0
  }
  
  public func double(forKey key: String) -> Double {
    return self.read(forKey: key) ?? 0.0
  }
  
  public func float(forKey key: String) -> Float {
    return self.read(forKey: key) ?? 0.0
  }
  
  public func url(forKey key: String) -> URL? {
    return self.read(forKey: key)
  }
  public func bool(forKey key: String) -> Bool {
    return self.read(forKey: key) ?? false
  }
  public func data(forKey key: String) -> Data? {
    return self.read(forKey: key)
  }

  // MARK: Remove
  public func removeCache(forKey key: String) {
    self.removeValue(forKey: key)
  }
  
  public func clearCache() {
    self.removeAll()
  }
}

// MARK: - In-Memory

open class InMemoryCache: CacheProvider {
  
  public static let standard: InMemoryCache = {
    return InMemoryCache()
  }()

  public lazy var internalCache = NSCache<NSString, AnyObject>()
  
  // MARK: Write
  public func cache(_ string: String, forKey key: String) {
    self.internalCache.setObject(string as NSString, forKey: key as NSString)
  }
  public func cache(_ int: Int, forKey key: String) {
    self.internalCache.setObject(NSNumber(value: int), forKey: key as NSString)
  }
  public func cache(_ double: Double, forKey key: String) {
    self.internalCache.setObject(NSNumber(value: double), forKey: key as NSString)
  }
  public func cache(_ float: Float, forKey key: String) {
    self.internalCache.setObject(NSNumber(value: float), forKey: key as NSString)
  }
  public func cache(_ url: URL, forKey key: String) {
    self.internalCache.setObject(url as NSURL, forKey: key as NSString)
  }
  public func cache(_ bool: Bool, forKey key: String) {
    self.internalCache.setObject(NSNumber(value: bool), forKey: key as NSString)
  }
  public func cache(_ data: Data, forKey key: String) {
    self.internalCache.setObject(data as NSData, forKey: key as NSString)
  }
  
  // MARK: Read
  public func string(forKey key: String) -> String? {
    guard let stringObject = self.internalCache.object(forKey: key as NSString) as? NSString else {
      return nil
    }
    
    return stringObject as String
  }
  public func integer(forKey key: String) -> Int {
    guard let numberObject = self.internalCache.object(forKey: key as NSString) as? NSNumber else {
      return 0
    }
    
    return numberObject.intValue
  }
  public func double(forKey key: String) -> Double {
    guard let numberObject = self.internalCache.object(forKey: key as NSString) as? NSNumber else {
      return 0.0
    }
    
    return numberObject.doubleValue
  }
  public func float(forKey key: String) -> Float {
    guard let numberObject = self.internalCache.object(forKey: key as NSString) as? NSNumber else {
      return 0.0
    }
    
    return numberObject.floatValue
  }
  public func url(forKey key: String) -> URL? {
    guard let urlObject = self.internalCache.object(forKey: key as NSString) as? NSURL else {
      return nil
    }
    
    return urlObject as URL
  }
  public func bool(forKey key: String) -> Bool {
    guard let numberObject = self.internalCache.object(forKey: key as NSString) as? NSNumber else {
      return false
    }
    
    return numberObject.boolValue
  }
  public func data(forKey key: String) -> Data? {
    guard let urlObject = self.internalCache.object(forKey: key as NSString) as? NSData else {
      return nil
    }
    
    return urlObject as Data
  }

  // MARK: Remove
  public func removeCache(forKey key: String) {
    internalCache.removeObject(forKey: key as NSString)
  }
  
  public func clearCache() {
    internalCache.removeAllObjects()
  }
}
