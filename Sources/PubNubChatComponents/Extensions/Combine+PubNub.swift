//
//  Combine+PubNub.swift
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

extension Publisher where Failure == Never {
  func weakAssign<T: AnyObject>(
    to keyPath: ReferenceWritableKeyPath<T, Output>,
    on object: T
  ) -> AnyCancellable {
    sink { [weak object] value in
      object?[keyPath: keyPath] = value
    }
  }
}

extension Publisher where Failure == Never, Output: Equatable {
  func weakAssign<T: AnyObject>(
    to keyPath: ReferenceWritableKeyPath<T, Output>,
    on object: T
  ) -> AnyCancellable {
    sink { [weak object] value in
      if value != object?[keyPath: keyPath] {
        object?[keyPath: keyPath] = value
      }
    }
  }
}

protocol CombineCompatible { }
extension UIControl: CombineCompatible { }
extension CombineCompatible where Self: UIControl {
  func publisher(for events: UIControl.Event) -> UIControlPublisher<Self> {
    return UIControlPublisher<Self>(control: self, events: events)
  }
}

struct UIControlPublisher<Control: UIControl>: Publisher {
  typealias Output = Control
  typealias Failure = Never
  
  let control: Control
  let controlEvents: UIControl.Event
  
  init(control: Control, events: UIControl.Event) {
    self.control = control
    self.controlEvents = events
  }
  
  func receive<S>(subscriber: S) where S: Subscriber, S.Failure == UIControlPublisher.Failure, S.Input == UIControlPublisher.Output {
    let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvents)
    subscriber.receive(subscription: subscription)
  }
}

final class UIControlSubscription<SubscriberType: Subscriber, Control: UIControl>: Subscription where SubscriberType.Input == Control {
  private var subscriber: SubscriberType?
  private let control: Control
  
  init(subscriber: SubscriberType, control: Control, event: UIControl.Event) {
    self.subscriber = subscriber
    self.control = control
    control.addTarget(self, action: #selector(eventHandler), for: event)
  }
  
  func request(_ demand: Subscribers.Demand) {}
  
  func cancel() {
    subscriber = nil
  }
  
  @objc private func eventHandler() {
    _ = subscriber?.receive(control)
  }
}
