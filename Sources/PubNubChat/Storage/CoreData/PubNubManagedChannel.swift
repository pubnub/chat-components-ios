//
//  ChannelDTO.swift
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
import SwiftUI

/// The CoreData managed `Channel` class used whenever a ChatChannel needs to be stored locally
@objc(PubNubManagedChannel)
public final class PubNubManagedChannel: NSManagedObject {
  /// Unique identifier for the Channel.
  @NSManaged public var id: String
  /// Name of the Channel.
  @NSManaged public var name: String?
  /// Functional type of the Channel.
  @NSManaged public var type: String
  /// The current state of the Channel
  @NSManaged public var status: String?
  /// Channel details you can display alongside the name.
  @NSManaged public var details: String?
  /// Image you can use to visually represent the channel.
  @NSManaged public var avatarURL: URL?
  /// Data blob that represents the Custom Properties that can be stored with the Channel.
  @NSManaged public var custom: Data
  /// Last time the remote object was changed.
  @NSManaged public var lastUpdated: Date?
  /// Caching value that changes whenever the remote object changes.
  @NSManaged public var eTag: String?

  // Relationships

  /// Messages that are currently associated with the Channel
  @NSManaged public var messages: Set<PubNubManagedMessage>
  /// Users that are currently associated with the Channel
  @NSManaged public var members: Set<PubNubManagedMember>

  // Derived Attributes
  /// Total amount of Members that are currently active on the Channel
  @NSManaged public var memberCount: Int

  // Transient Property
}

// MARK: ManagedChannelEntity Impl.

extension PubNubManagedChannel: ManagedChannelEntity {
  public var pubnubChannelID: String {
    return id
  }

  public var memberEntityCount: Int {
    return members.count
  }

  public var presentMemberEntityCount: Int {
    return members.filter({ $0.isPresent }).count
  }

  public var managedMembers: Set<PubNubManagedMember> {
    return members
  }

  public var managedMessages: Set<PubNubManagedMessage> {
    return messages
  }

  public func convert<Custom: ChannelCustomData>() -> ChatChannel<Custom> {
    return ChatChannel(
      id: id,
      name: name,
      type: type,
      status: status,
      details: details,
      avatarURL: avatarURL,
      updated: lastUpdated,
      eTag: eTag,
      custom: (try? Constant.jsonDecoder.decode(Custom.self, from: custom)) ?? Custom()
    )
  }

  @discardableResult
  public static func insertOrUpdate<Custom: ChannelCustomData>(
    channel: ChatChannel<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedChannel {
    if let existingChannel = try? context.fetch(
      channelBy(channelID: channel.id)
    ).first {
      try existingChannel.update(from: channel)
      return existingChannel
    } else {
      // Create new object from context
      return try insert(channel: channel, into: context)
    }
  }

  static func insert<Custom: ChannelCustomData>(
    channel: ChatChannel<Custom>,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedChannel {
    return try context.insertNew { (object: PubNubManagedChannel) in
      try object.update(from: channel)
    }
  }

  @discardableResult
  public static func patch<Custom: ChannelCustomData>(
    usingPatch patcher: ChatChannel<Custom>.Patcher,
    into context: NSManagedObjectContext
  ) throws -> PubNubManagedChannel {
    if let existingChannel = try context.fetch(
      channelBy(pubnubId: patcher.id)
    ).first {
      let chatChannel = existingChannel.convert().patch(patcher)
      try existingChannel.update(from: chatChannel)
      
      return existingChannel
    } else {
      throw ChatError.missingRequiredData
    }
  }

  func update<Custom: ChannelCustomData>(
    from channel: ChatChannel<Custom>
  ) throws {
    id = channel.id
    name = channel.name
    type = channel.type
    status = channel.status
    details = channel.details
    avatarURL = channel.avatarURL
    custom = try channel.custom.custom.jsonDataResult.get()
    lastUpdated = channel.updated
    eTag = channel.eTag
  }

  @discardableResult
  public static func remove(
    channelId: String,
    from context: NSManagedObjectContext
  ) -> PubNubManagedChannel? {
    if let existingChannel = try? context.fetch(
      channelBy(channelID: channelId)
    ).first {
      context.delete(existingChannel)
      return existingChannel
    }

    return nil
  }
}

// MARK: ManagedChannelEntityFetches Impl.

extension PubNubManagedChannel: ManagedChannelEntityFetches {
  public static func channelBy(channelID: String) -> NSFetchRequest<PubNubManagedChannel> {
    let request = NSFetchRequest<PubNubManagedChannel>(entityName: entityName)
    request.predicate = NSPredicate(format: "id == %@", channelID)

    return request
  }

  public static func channelBy(pubnubId: String) -> NSFetchRequest<PubNubManagedChannel> {
    return channelBy(channelID: pubnubId)
  }
}
