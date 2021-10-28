//
//  MessageInputComponentViewModel.swift
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

import UIKit
import Combine

import PubNubChat
import CoreData

extension ChatProvider
where ManagedEntities: ChatViewModels,
      ManagedEntities: ManagedChatEntities,
      ManagedEntities.Channel.MemberViewModel == ManagedEntities.Member {
  
  open func messageInputComponentViewModel(
    channel: ManagedEntities.Channel,
    customTheme: MessageInputComponentTheme? = nil
  ) -> MessageInputComponentViewModel<ModelData, ManagedEntities> {
    return MessageInputComponentViewModel(
      provider: self,
      selectedChannel: channel,
      componentTheme: customTheme ?? themeProvider.template.messageInputComponent
    )
  }
  
  open func messageInputComponentViewModel(
    channelId: String,
    customTheme: MessageInputComponentTheme? = nil
  ) throws -> MessageInputComponentViewModel<ModelData, ManagedEntities> {
    guard let channel = try fetchChannel(byPubNubId: channelId) else {
      throw ChatError.missingRequiredData
    }
    
    return messageInputComponentViewModel(
      channel: channel,
      customTheme: customTheme
    )
  }
}

public class MessageInputComponentViewModel<ModelData, ManagedEntities>
  where ModelData: ChatCustomData,
        ManagedEntities: ChatViewModels,
        ManagedEntities: ManagedChatEntities,
        ManagedEntities.Channel.MemberViewModel == ManagedEntities.Member
{

  public let provider: ChatProvider<ModelData, ManagedEntities>
  public let selectedChannel: ManagedEntities.Channel
  
  @Published public var componentTheme: MessageInputComponentTheme
  
  @Published public var typingMemberIds: Set<String> = []
  
  var forcePublisheTypingSubject = PassthroughSubject<Bool, Never>()
    
  public init(
    provider: ChatProvider<ModelData, ManagedEntities>,
    selectedChannel: ManagedEntities.Channel,
    componentTheme: MessageInputComponentTheme
  ) {
    self.provider = provider
    self.selectedChannel = selectedChannel
    self.componentTheme = componentTheme
  }
  
  public func configuredComponentView(
    cancelStore: inout Set<AnyCancellable>
  ) -> MessageInputComponent {
    let messageInput = componentTheme.viewType.init()
    
    messageInput.theming(componentTheme, cancelIn: &cancelStore)
    
    // Typing Indicator Publisher
    messageInput.typingDidChangeSubject
      .throttle(for: .seconds(3), scheduler: RunLoop.main, latest: true)
      .merge(with: forcePublisheTypingSubject)
      .combineLatest(componentTheme.$publishTypingIndicator)
      .sink { [weak self] value, shoudPublish in
        guard let self = self, shoudPublish, value else { return }
        self.provider.dataProvider.send(
          isTyping: value,
          on: self.selectedChannel.pubnubChannelID
        )
      }
      .store(in: &cancelStore)
    
    // Typing Indicator Receiver
    componentTheme.typingIndicatorService
      .publisher(for: selectedChannel.pubnubChannelID)
      .combineLatest(componentTheme.$displayTypingIndicator)
      .sink { [weak self] memberIds, shouldDisplay in
        if shouldDisplay {
          self?.typingMemberIds = memberIds
        } else {
          self?.typingMemberIds = []
        }
      }.store(in: &cancelStore)

    messageInput.sendMessageSubject
      .sink { [weak self] component, message in
        self?.sendMessage(component, inputText: message)
      }
      .store(in: &cancelStore)
    
    return messageInput
  }
  var isTyping = false
  
  // MARK: - Send a message
  
  public var messageWillSend: (
    (MessageInputComponentViewModel<ModelData, ManagedEntities>, ChatMessage<ModelData>) -> ChatMessage<ModelData>
  )?
  
  public var messageDidSend: (
    (MessageInputComponentViewModel<ModelData, ManagedEntities>, ChatMessage<ModelData>, Future<ChatMessage<ModelData>, Error>) -> Void
  )?
  
  open func sendMessage(_ messageInput: MessageInputComponent, inputText: String) {
    // Create Message Object
    var message = ChatMessage(
      content: constructOutgoingContent(inputText: inputText),
      pubnubUserId: provider.currentUserId,
      pubnubChannelId: selectedChannel.pubnubChannelID
    )
    
    message = messageWillSend?(self, message) ?? message
    
    let future = Future<ChatMessage<ModelData>, Error>({ [weak self] promise in
      self?.provider.dataProvider.sendRemoteMessage(SendMessageRequest(message: message)) { result in
        promise(result)
      }
    })
     
    messageDidSend?(self, message, future)

    messageInput.clearMessageInput()
    forcePublisheTypingSubject.send(false)
  }
  
  open func constructOutgoingContent(inputText: String) -> ChatMessage<ModelData>.Content {
    if let url = URL(string: inputText), !inputText.split(separator: " ").flatMap({ String($0).detectedURLs() }).isEmpty {
      return ChatMessage<ModelData>.Content(
        id: UUID().uuidString,
        dateCreated: Date(),
        content: .link(url),
        custom: constructOutgoingContentCustomData()
      )
    } else {
      return ChatMessage<ModelData>.Content(
        id: UUID().uuidString,
        dateCreated: Date(),
        content: .text(inputText),
        custom: constructOutgoingContentCustomData()
      )
    }
  }

  open func constructOutgoingContentCustomData() -> ModelData.Message {
    return .init()
  }
}
