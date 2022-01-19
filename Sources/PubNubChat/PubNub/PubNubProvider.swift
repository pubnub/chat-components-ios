//
//  PubNubProvider.swift
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
import Combine

import PubNub

// MARK: - Protocol Wrapper
public typealias PubNubObjectAPI = PubNubUserAPI & PubNubChannelAPI & PubNubMembershipAPI & PubNubMemberAPI
public typealias PubNubAPI = SubscribeAPI & PubNubObjectAPI & MessageAPI & PresenceAPI & PubNubConfigurable & PubNubBase

// MARK: - Configuration Provider
public protocol PubNubConfigurable {
  var configuration: PubNubConfiguration { get }
  mutating func setConsumer(identifier: String, value: String)
}

public protocol PubNubBase {
  var pubnub: PubNub? { get }
}

extension PubNub: PubNubConfigurable {}

extension PubNub: PubNubBase {
  public var pubnub: PubNub? {
    return self
  }
}

// MARK: - KeySet Provider
public protocol PubNubKeySetProvider {
  var subscribeKey: String { get set }
  var publishKey: String? { get set }
}

// MARK: Subscribe/Data Listener

extension ChatDataProvider {
  
  open func syncPubnubSubscribeListener(_ listener: SubscriptionListener) {
    
    listener.didReceiveBatchSubscription = { [weak self] events in
      guard let self = self else { return }
      var users = [PubNubUUIDMetadataChangeset]()
      var channels = [PubNubChannelMetadataChangeset]()

      var members = [ChatMember<ModelData>]()
      var messages = [ChatMessage<ModelData>]()
      var presenceChanges = [ChatMember<ModelData>]()

      for event in events {
        switch event {
        case .messageReceived(let message):
          PubNub.log.debug("Listener: Message received \(message.published)")

          do {
            messages.append(try ChatMessage<ModelData>(from: message))
          } catch {
            PubNub.log.error("Listener Message received conversion error \(error)")
          }

        case .signalReceived(let signal):
          PubNub.log.debug("Listener: Signal received \(signal)")
          
          if let typingIndicator = try? signal.payload.decode(TypingIndicatorSignal.self) {
            self.member(
              userId: signal.publisher ?? "",
              didStartTypingOn: signal.channel,
              timetoken: typingIndicator == .typingOn ? signal.published.timetokenDate : nil
            )
          } else {
            PubNub.log.error("Listener Error: Signal received but could not parse payload")
          }
          
        case .connectionStatusChanged(let status):
          PubNub.log.info("Listener Subscription connection changed \(status)")
        case .subscriptionChanged(let subscription):
          PubNub.log.debug("Listener no-op: Subscription changed \(subscription)")
        case .presenceChanged(let presence):
          PubNub.log.debug("Listener: Presence changed \(presence)")
          if presence.refreshHereNow {
            self.syncHereNow(.init(channels: [presence.channel]), completion: nil)
          } else {
            // Convert event(s) into Memberships
            let memberships = ChatMember<ModelData>.presenceMemberships(
              channelId: presence.channel, changeActions: presence.actions
            )
            presenceChanges.append(contentsOf: memberships)
          }
        case .uuidMetadataSet(let userChangeset):
          PubNub.log.debug("Listener: User Metadata set \(userChangeset)")
          users.append(userChangeset)
        
        case .uuidMetadataRemoved(metadataId: let metadataId):
          PubNub.log.debug("Listener: User Metadata removed \(metadataId)")
          self.removeStoredUser(userId: metadataId)
      
        case .channelMetadataSet(let channelChangeset):
          PubNub.log.debug("Listener: Channel Metadata set \(channelChangeset)")
          channels.append(channelChangeset)
          
        case .channelMetadataRemoved(metadataId: let metadataId):
          PubNub.log.debug("Listener: Channel Metadata removed \(metadataId)")
          self.removeStoredChannel(channelId: metadataId)

        case .membershipMetadataSet(let membership):
          PubNub.log.debug("Listener: Membership Metadata set \(membership)")
          do {
            members.append(try ChatMember<ModelData>(from: membership))
          } catch {
            PubNub.log.error("Listener Membership Metadata received conversion error \(error)")
          }
          
        case .membershipMetadataRemoved(let membership):
          PubNub.log.debug("Listener: Membership Metadata removed \(membership)")
          self.removeStoredMember(
            channelId: membership.channelMetadataId, userId: membership.uuidMetadataId
          )

        case .messageActionAdded(let messageAction):
          PubNub.log.debug("Listener no-op: Message Action added \(messageAction)")
        case .messageActionRemoved(let messageAction):
          PubNub.log.debug("Listener no-op: Message Action removed \(messageAction)")
        case .fileUploaded(let file):
          PubNub.log.debug("Listener no-op: File uploaded \(file)")
        case .subscribeError(let error):
          PubNub.log.error("Listener Subscribe error \(error)")
        }
      }

      // Process the batch updates
      self.load(messages: messages)
      self.load(members: presenceChanges)
      self.load(members: members)
    }
  }
}

