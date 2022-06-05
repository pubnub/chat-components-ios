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
public typealias PubNubObjectAPI = PubNubUserAPI & PubNubChannelAPI & PubNubMemberAPI
public typealias PubNubAPI = SubscribeAPI & PubNubObjectAPI & MessageAPI & MessageActionAPI & PresenceAPI & PubNubConfigurable & PubNubBase

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

      var members = [ChatMember<ModelData>]()
      var messages = [ChatMessage<ModelData>]()
      var presenceChanges = [ChatMember<ModelData>]()
      var messageActions = [ChatMessageAction<ModelData>]()

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
        case .userUpdated(let patcher):
          PubNub.log.debug("Listener: User Updated \(patcher)")
          self.patch(user: .init(pubnub: patcher))
        
        case .userRemoved(let user):
          PubNub.log.debug("Listener: User Removed \(user)")
          self.removeStoredUser(userId: user.id)
      
        case .spaceUpdated(let patcher):
          PubNub.log.debug("Listener: Channel Updated \(patcher)")
          self.patch(channel: .init(pubnub: patcher))

        case .spaceRemoved(let space):
          PubNub.log.debug("Listener: Channel Removed \(space)")
          self.removeStoredChannel(channelId: space.id)

        case .membershipUpdated(let membership):
          PubNub.log.debug("Listener: Membership Updated \(membership)")
          members.append(.init(pubnub: membership))

        case .membershipRemoved(let membership):
          PubNub.log.debug("Listener: Membership Removed \(membership)")
          self.removeStoredMember(
            channelId: membership.space.id, userId: membership.user.id
          )

        case .messageActionAdded(let messageAction):
          PubNub.log.debug("Listener: Message Action added \(messageAction)")
          do {
            messageActions.append(try ChatMessageAction<ModelData>(from: messageAction))
          } catch {
            PubNub.log.error("Listener Message Action received conversion error \(error)")
          }
        case .messageActionRemoved(let messageAction):
          PubNub.log.debug("Listener: Message Action removed \(messageAction)")
          self.removeStoredMessageAction(messageActionId: messageAction.pubnubId)
          
        case .fileUploaded(let file):
          PubNub.log.debug("Listener no-op: File uploaded \(file)")
        case .subscribeError(let error):
          PubNub.log.error("Listener Subscribe error \(error)")
        
        case .uuidMetadataSet(_):
          /* no-op for Object v2 */
          break
        case .uuidMetadataRemoved(metadataId: _):
          /* no-op for Object v2 */
          break
        case .channelMetadataSet(_):
          /* no-op for Object v2 */
          break
        case .channelMetadataRemoved(metadataId: _):
          /* no-op for Object v2 */
          break
        case .membershipMetadataSet(_):
          /* no-op for Object v2 */
          break
        case .membershipMetadataRemoved(_):
          /* no-op for Object v2 */
          break
        }
      }

      // Process the batch updates
      self.load(messages: messages)
      self.load(members: presenceChanges)
      self.load(members: members)
    }
  }
}

