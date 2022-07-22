//
//  MessageActionAPI.swift
//
//  PubNub Real-time Cloud-Hosted Push API and Push Notification Client Frameworks
//  Copyright © 2022 PubNub Inc.
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
import PubNubMembership

public typealias ChatMessageActionHistoryClosure = (
  Result<(messagesByChannelId: [String: [PubNubMessage]], next: PubNubBoundedPage?), Error>
) -> Void

public protocol MessageActionAPI {
  func sendMessageAction<Custom: ChatCustomData>(
    _ request: MessageActionSendRequest<Custom>,
    completion: ((Result<ChatMessageAction<Custom>, Error>) -> Void)?
  )
  
  func fetchMessageActions<Custom: ChatCustomData>(
    _ request: MessageActionFetchRequest,
    into: Custom.Type,
    completion: ((Result<(actions: [ChatMessageAction<Custom>], next: MessageActionFetchRequest?), Error>) -> Void)?
  )
  
  func removeMessageAction<Custom: ChatCustomData>(
    _ request: MessageActionRequest<Custom>,
    completion: ((Result<ChatMessageAction<Custom>, Error>) -> Void)?
  )
}

extension MessageActionAPI {
  func fetchMessageActionsPublisher<Custom: ChatCustomData>(
    _ request: MessageActionFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(actions: [ChatMessageAction<Custom>], next: MessageActionFetchRequest?), Error> {
    return Future { promise in
      fetchMessageActions(request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  
  public func fetchMessageActionsPagesPublisher<Custom: ChatCustomData>(
    _ request: MessageActionFetchRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([ChatMessageAction<Custom>], MessageActionFetchRequest?), PaginationError<MessageActionFetchRequest>> {
    
    let pagedPublisher = CurrentValueSubject<MessageActionFetchRequest, PaginationError<MessageActionFetchRequest>>(request)
    
    return pagedPublisher
      .flatMap({ request in
        fetchMessageActionsPublisher(request, into: customType)
          .mapError { PaginationError<MessageActionFetchRequest>(request: request, error: $0) }
      })
      .handleEvents(receiveOutput: { output in
        if let request = output.next {
          pagedPublisher.send(request)
        } else {
          pagedPublisher.send(completion: .finished)
        }
      })
      .map { ($0.actions, $0.next) }
      .eraseToAnyPublisher()
  }
}

// MARK: - PubNub Ext

extension PubNubProvider {
  public func fetchMessageActions<Custom: ChatCustomData>(
    _ request: MessageActionFetchRequest,
    into: Custom.Type,
    completion: ((Result<(actions: [ChatMessageAction<Custom>], next: MessageActionFetchRequest?), Error>) -> Void)?
  ) {
    pubnub.fetchMessageActions(
      channel: request.channel,
      page: request.page,
      custom: .init(customConfiguration: request.config?.mergeChatConsumerID())
    ) { result in
      switch result {
      case .success((let actions, let next)):
        completion?(.success((actions.compactMap({ try? $0.transcode() }), request.next(page: next))))
      case .failure(let error):
        completion?(.failure(error))
      }
    }
  }
  
  public func sendMessageAction<Custom: ChatCustomData>(
    _ request: MessageActionSendRequest<Custom>,
    completion: ((Result<ChatMessageAction<Custom>, Error>) -> Void)?
  ) {
    pubnub.addMessageAction(
      channel: request.channelId,
      type: request.actionType,
      value: request.actionValue,
      messageTimetoken: request.messageTimetoken,
      custom: .init(customConfiguration: request.config?.mergeChatConsumerID())
    ) { result in
      completion?(result.map { action in
        return ChatMessageAction(
          actionTimetoken: action.actionTimetoken,
          parentTimetoken: action.messageTimetoken,
          sourceType: action.actionType,
          value: action.actionValue,
          pubnubUserId: action.publisher,
          pubnubChannelId: action.channel
        )
      })
    }
  }
  
  public func removeMessageAction<Custom: ChatCustomData>(
    _ request: MessageActionRequest<Custom>,
    completion: ((Result<ChatMessageAction<Custom>, Error>) -> Void)?
  ) {
    pubnub.removeMessageActions(
      channel: request.messageAction.pubnubChannelId,
      message: request.messageAction.messageTimetoken,
      action: request.messageAction.actionTimetoken,
      custom: .init(customConfiguration: request.config?.mergeChatConsumerID())
    ) { result in
        switch result {
        case .success:
          completion?(.success(request.messageAction))
        case .failure(let error):
          completion?(.failure(error))
        }
      }
  }
}

// MARK: - Requests

public struct MessageActionRequest<Custom: ChatCustomData> {
  public let requestId: String = UUID().uuidString
  
  public let messageAction: ChatMessageAction<Custom>
  
  public var config: PubNubConfiguration?
  
  public init(
    messageAction: ChatMessageAction<Custom>,
    config: PubNubConfiguration? = nil
  ) {
    self.messageAction = messageAction
    self.config = config
  }
}

extension MessageActionRequest: Equatable {
  public static func == (lhs: MessageActionRequest, rhs: MessageActionRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

// MARK: Semd Message Action Request

public struct MessageActionSendRequest<Custom: ChatCustomData> {
  public let requestId: String = UUID().uuidString
  
  public var channelId: String
  public var messageTimetoken: Timetoken
  
  public var actionType: String
  public var actionValue: String
  
  public var config: PubNubConfiguration?
  
  public init(
    messageTimetoken: Timetoken,
    channelId: String,
    actionType: String,
    actionValue: String,
    config: PubNubConfiguration? = nil
  ) {
    self.messageTimetoken = messageTimetoken
    self.channelId = channelId
    self.actionType = actionType
    self.actionValue = actionValue
    self.config = config
  }
  
  public init(
    parent: ChatMessage<Custom>,
    actionType: String,
    actionValue: String,
    config: PubNubConfiguration? = nil
  ) {
    self.init(
      messageTimetoken: parent.timetoken,
      channelId: parent.pubnubChannelId,
      actionType: actionType,
      actionValue: actionValue,
      config: config
    )
  }
}

extension MessageActionSendRequest: Equatable {
  public static func == (lhs: MessageActionSendRequest, rhs: MessageActionSendRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

// MARK: Fetch Message Action Request

public struct MessageActionFetchRequest {
  public let requestId: String = UUID().uuidString
  
  public let channel: String

  public var page: PubNubBoundedPage?
  
  public var config: PubNubConfiguration?
  
  public init(
    channel: String,
    limit: Int? = nil,
    start: Timetoken? = nil,
    end: Timetoken? = nil,
    config: PubNubConfiguration? = nil
  ) {
    self.channel = channel
    page = PubNubBoundedPageBase(start: start, end: end, limit: limit)
    self.config = config
  }
  
  func next(page: PubNubBoundedPage?) -> MessageActionFetchRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension MessageActionFetchRequest: Equatable {
  public static func == (lhs: MessageActionFetchRequest, rhs: MessageActionFetchRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}
