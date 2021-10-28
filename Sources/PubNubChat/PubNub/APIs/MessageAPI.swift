//
//  MessageAPI.swift
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

public typealias ChatMessageHistoryClosure = (
  Result<(messagesByChannelId: [String: [PubNubMessage]], next: PubNubBoundedPage?), Error>
) -> Void

public protocol MessageAPI {
  func sendMessage<Custom: ChatCustomData>(
    _ request: SendMessageRequest<Custom>,
    completion: ((Result<ChatMessage<Custom>, Error>) -> Void)?
  )
  
  func sendSignal(
    channelId: String,
    payload: JSONCodable,
    completion: ((Result<Timetoken, Error>) -> Void)?
  )
  
  func fetchMessageHistory<Custom: ChatCustomData>(
    _ request: MessageHistoryRequest,
    into: Custom.Type,
    completion: ((Result<(messageByChannelId: [String: [ChatMessage<Custom>]], next: MessageHistoryRequest?), Error>) -> Void)?
  )
}

extension MessageAPI {
  func fetchMessageHistoryPublisher<Custom: ChatCustomData>(
    _ request: MessageHistoryRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<(messageByChannelId: [String: [ChatMessage<Custom>]], next: MessageHistoryRequest?), Error> {
    return Future { promise in
      fetchMessageHistory(request, into: customType) { promise($0) }
    }.eraseToAnyPublisher()
  }
  
  public func fetchHistoryPagesPublisher<Custom: ChatCustomData>(
    _ request: MessageHistoryRequest,
    into customType: Custom.Type
  ) -> AnyPublisher<([String: [ChatMessage<Custom>]], MessageHistoryRequest?), PaginationError<MessageHistoryRequest>> {
    
    let pagedPublisher = CurrentValueSubject<MessageHistoryRequest, PaginationError<MessageHistoryRequest>>(request)
    
    return pagedPublisher
      .flatMap({ request in
        fetchMessageHistoryPublisher(request, into: customType)
          .mapError { PaginationError<MessageHistoryRequest>(request: request, error: $0) }
      })
      .handleEvents(receiveOutput: { output in
        if let request = output.next {
          pagedPublisher.send(request)
        } else {
          pagedPublisher.send(completion: .finished)
        }
      })
      .map { ($0.messageByChannelId, $0.next) }
      .eraseToAnyPublisher()
  }
}

// MARK: - PubNub Ext

extension PubNub: MessageAPI {
  public func fetchMessageHistory<Custom: ChatCustomData>(
    _ request: MessageHistoryRequest,
    into: Custom.Type,
    completion: ((Result<(messageByChannelId: [String: [ChatMessage<Custom>]], next: MessageHistoryRequest?), Error>) -> Void)?
  ) {
    fetchMessageHistory(
      for: request.channels,
      includeActions: request.actionsInResponse,
      includeMeta: request.metaInResponse,
      includeUUID: request.uuidInResponse,
      includeMessageType: request.messageTypeInResponse,
      page: request.page
    ) { result in
      switch result {
      case .success((let messagesByChannel, let next)):
        completion?(.success((messagesByChannel.mapValues({ $0.compactMap({ try? $0.transcode() }) }), request.next(page: next))))
      case .failure(let error):
        completion?(.failure(error))
      }
    }
  }
  
  public func sendSignal(
    channelId: String,
    payload: JSONCodable,
    completion: ((Result<Timetoken, Error>) -> Void)?
  ) {
    signal(channel: channelId, message: payload, completion: completion)
  }

  public func sendMessage<Custom: ChatCustomData>(
    _ request: SendMessageRequest<Custom>,
    completion: ((Result<ChatMessage<Custom>, Error>) -> Void)?
  ) {
    publish(
      channel: request.message.pubnubChannelId,
      message: request.message.content,
      shouldStore: request.storeInHistory,
      storeTTL: request.ttl,
      meta: request.metadata,
      shouldCompress: request.shouldCompress
    ) { result in
      completion?(result.map { timetoken in
        var requestMessage = request.message
        requestMessage.timetoken = timetoken
        return requestMessage
      })
    }
  }
}

// MARK: - Requests

public struct SendMessageRequest<Custom: ChatCustomData> {
  public let requestId: String = UUID().uuidString

  public let message: ChatMessage<Custom>
  public let storeInHistory: Bool?
  public let shouldCompress: Bool
  public let ttl: Int?
  public let metadata: JSONCodable?
  
  public var config: PubNubConfiguration?

  public init(
    message: ChatMessage<Custom>,
    storeInHistory: Bool? = nil,
    shouldCompress: Bool = false,
    ttl: Int? = nil,
    metadata: JSONCodable? = nil,
    config: PubNubConfiguration? = nil
  ) {
    self.message = message
    self.storeInHistory = storeInHistory
    self.shouldCompress = shouldCompress
    self.ttl = ttl
    self.metadata = metadata
    self.config = config
  }
}

extension SendMessageRequest: Equatable {
  public static func == (lhs: SendMessageRequest, rhs: SendMessageRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

// MARK: MessageHistory Request

public struct MessageHistoryRequest {
  public let requestId: String = UUID().uuidString

  public let channels: [String]
  public var actionsInResponse: Bool
  public var metaInResponse: Bool
  public var uuidInResponse: Bool
  public var messageTypeInResponse: Bool
  public var page: PubNubBoundedPage?
  
  public var config: PubNubConfiguration?

  public init(
    channels: [String],
    actionsInResponse: Bool = true,
    metaInResponse: Bool = false,
    uuidInResponse: Bool = true,
    messageTypeInResponse: Bool = true,
    limit: Int? = nil,
    start: Timetoken?,
    end: Timetoken? = nil,
    config: PubNubConfiguration? = nil
  ) {
    self.channels = channels
    self.actionsInResponse = actionsInResponse
    self.metaInResponse = metaInResponse
    self.uuidInResponse = uuidInResponse
    self.messageTypeInResponse = messageTypeInResponse
    page = PubNubBoundedPageBase(start: start, end: end, limit: limit)
    self.config = config
  }
  
  func next(page: PubNubBoundedPage?) -> MessageHistoryRequest? {
    guard let page = page, page.start != nil, page.start != self.page?.end else {
      return nil
    }
    
    var request = self
    request.page = page
    return request
  }
}

extension MessageHistoryRequest: Equatable {
  public static func == (lhs: MessageHistoryRequest, rhs: MessageHistoryRequest) -> Bool {
    return lhs.requestId == rhs.requestId
  }
}

// MARK: TypingIndicatorSignal

public enum TypingIndicatorSignal: String, JSONCodable {
  case typingOn = "typing_on"
  case typingOff = "typing_off"

  public enum CodingKeys: String, CodingKey {
    case type
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let rawString = try container.decode(String.self, forKey: .type)
    
    try self.init(rawString)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.rawValue, forKey: .type)
  }
}

extension RawRepresentable {
  init(_ rawValue: RawValue) throws {
    guard let value = Self(rawValue: rawValue) else {
      PubNub.log.error("Error `RawRepresentable` missing rawValue for \(rawValue)")
      throw ChatError.missingRequiredData
    }
    self = value
  }
}
