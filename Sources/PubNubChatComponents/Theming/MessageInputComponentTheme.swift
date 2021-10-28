//
//  MessageInputComponentTheme.swift
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

public class MessageInputComponentTheme: ObservableObject {
  
  public var viewType: MessageInputComponent.Type
  public var typingIndicatorService: TypingIndicatorService
  
  @Published public var backgroundColor: UIColor?
  @Published public var placeholderText: String?
  @Published public var placeholderTextColor: UIColor?
  @Published public var placeholderTextFont: UIFont?
  @Published public var textInputTheme: InputTextViewComponentTheme
  @Published public var sendButtonTheme: ButtonComponentTheme
  @Published public var publishTypingIndicator: Bool
  @Published public var displayTypingIndicator: Bool
  
  public init(
    viewType: MessageInputComponent.Type,
    backgroundColor: UIColor?,
    placeholderText: String?,
    placeholderTextColor: UIColor?,
    placeholderTextFont: UIFont?,
    textInputTheme: InputTextViewComponentTheme,
    sendButton: ButtonComponentTheme,
    typingIndicatorService: TypingIndicatorService,
    publishTypingIndicator: Bool,
    displayTypingIndicator: Bool
  ) {
    self.viewType = viewType
    self.typingIndicatorService = typingIndicatorService
    self.backgroundColor = backgroundColor
    self.placeholderText = placeholderText
    self.placeholderTextColor = placeholderTextColor
    self.placeholderTextFont = placeholderTextFont
    self.textInputTheme = textInputTheme
    self.sendButtonTheme = sendButton
    self.publishTypingIndicator = publishTypingIndicator
    self.displayTypingIndicator = displayTypingIndicator
  }
}

extension MessageInputComponent {
  public func theming(_ theme: MessageInputComponentTheme, cancelIn store: inout Set<AnyCancellable>) {
    theme.$backgroundColor.weakAssign(to: \.backgroundColor, on: self).store(in: &store)
    
    theme.$placeholderText.sink { [weak self] text in
      self?.placeholder = text
    }.store(in: &store)
    
    theme.$placeholderTextColor.sink { [weak self] textColor in
      self?.placeholderTextColor = textColor
    }.store(in: &store)
    
    theme.$placeholderTextFont.sink { [weak self] textFont in
      self?.placeholderTextFont = textFont
    }.store(in: &store)
    
    var localStore = Set<AnyCancellable>()
    theme.$textInputTheme.sink { [weak self] textInputTheme in
      self?.inputTextView?.theming(textInputTheme, cancelIn: &localStore)
    }.store(in: &store)
    
    theme.$sendButtonTheme.sink { [weak self] sendButtonTheme in
      self?.sendButton?.theming(sendButtonTheme, cancelIn: &localStore)
    }.store(in: &store)
    
    store.formUnion(localStore)
  }
}

// MARK: UIButton Theme impl.

public class ButtonComponentTheme: ObservableObject {

  @Published public var backgroundColor: UIColor?
  @Published public var buttonType: UIButton.ButtonType
  @Published public var tintColor: UIColor?
  @Published public var title: ButtonTitleStateTheme
  @Published public var titleHighlighted: ButtonTitleStateTheme
  @Published public var titleFont: UIFont?
  @Published public var image: ButtonImageStateTheme
  @Published public var imageHighlighted: ButtonImageStateTheme

  public init(
    backgroundColor: UIColor?,
    buttonType: UIButton.ButtonType,
    tintColor: UIColor?,
    title: ButtonTitleStateTheme,
    titleHighlighted: ButtonTitleStateTheme?,
    titleFont: UIFont?,
    image: ButtonImageStateTheme,
    imageHighlighted: ButtonImageStateTheme?
  ) {
    self.backgroundColor = backgroundColor
    self.buttonType = buttonType
    self.tintColor = tintColor
    self.title = title
    self.titleHighlighted = titleHighlighted ?? title
    self.titleFont = titleFont
    self.image = image
    self.imageHighlighted = imageHighlighted ?? image
  }
  
  public convenience init(
    buttonTheme: ButtonComponentTheme
  ) {
    self.init(
      backgroundColor: buttonTheme.backgroundColor,
      buttonType: buttonTheme.buttonType,
      tintColor: buttonTheme.tintColor,
      title: buttonTheme.title,
      titleHighlighted: buttonTheme.titleHighlighted,
      titleFont: buttonTheme.titleFont,
      image: buttonTheme.image,
      imageHighlighted: buttonTheme.imageHighlighted
    )
  }
}

public class ButtonTitleStateTheme: ObservableObject {
  @Published public var title: String?
  @Published public var attributedTitle: NSAttributedString?
  @Published public var titleColor: UIColor?
  @Published public var titleShadowColor: UIColor?
  
  public init(
    title: String?,
    attributedTitle: NSAttributedString?,
    titleColor: UIColor?,
    titleShadowColor: UIColor?
  ) {
    self.title = title
    self.attributedTitle = attributedTitle
    self.titleColor = titleColor
    self.titleShadowColor = titleShadowColor
  }
  
  func assignTheme(_ button: UIButton?, controlState: UIControl.State = .normal, cancelIn store: inout Set<AnyCancellable>) {
    $title.sink { [weak button] titleValue in
      button?.setTitle(titleValue, for: controlState)
    }.store(in: &store)
    
    $attributedTitle.sink { [weak button] attributedTitleValue in
      button?.setAttributedTitle(attributedTitleValue, for: controlState)
    }.store(in: &store)
    
    $titleColor.sink { [weak button] titleColorValue in
      button?.setTitleColor(titleColorValue, for: controlState)
    }.store(in: &store)
    
    $titleShadowColor.sink { [weak button] shadowColorValue in
      button?.setTitleShadowColor(shadowColorValue, for: controlState)
    }.store(in: &store)
  }
  
  public static var empty: ButtonTitleStateTheme {
    return ButtonTitleStateTheme(
      title: nil,
      attributedTitle: nil,
      titleColor: nil,
      titleShadowColor: nil
    )
  }
}

public class ButtonImageStateTheme: ObservableObject {
  @Published public var image: UIImage?
  @Published public var backgroundImage: UIImage?
  
  public init(
    image: UIImage?,
    backgroundImage: UIImage?
  ) {
    self.image = image
    self.backgroundImage = backgroundImage
  }
  
  func assignTheme(_ button: UIButton?, controlState: UIControl.State = .normal, cancelIn store: inout Set<AnyCancellable>) {
    $image.sink { [weak button] imageValue in
      button?.setImage(imageValue, for: controlState)
    }.store(in: &store)
    
    $backgroundImage.sink { [weak button] imageValue in
      button?.setBackgroundImage(imageValue, for: controlState)
    }.store(in: &store)
  }
  
  public static var empty: ButtonImageStateTheme {
    return ButtonImageStateTheme(
      image: nil,
      backgroundImage: nil
    )
  }
}

extension UIButton {
  public func theming(_ theme: ButtonComponentTheme, cancelIn store: inout Set<AnyCancellable>) {
//    theme.$backgroundColor.sink { [weak self] colorChange in
//      self?.backgroundColor = colorChange
//      self?.inputAccessoryView?.backgroundColor = colorChange
//    }.store(in: &store)

    theme.$backgroundColor.weakAssign(to: \.backgroundColor, on: self).store(in: &store)
    theme.$tintColor.weakAssign(to: \.tintColor, on: self).store(in: &store)
    
    var localStore = Set<AnyCancellable>()
    theme.$title.sink { [weak self] titleStateTheme in
      titleStateTheme.assignTheme(self, cancelIn: &localStore)
    }.store(in: &store)
    theme.$titleHighlighted.sink { [weak self] titleStateTheme in
      titleStateTheme.assignTheme(self, controlState: .highlighted, cancelIn: &localStore)
    }.store(in: &store)

    theme.$image.sink { [weak self] imageStateTheme in
      imageStateTheme.assignTheme(self, cancelIn: &localStore)
    }.store(in: &store)
    theme.$imageHighlighted.sink { [weak self] imageStateTheme in
      imageStateTheme.assignTheme(self, controlState: .highlighted, cancelIn: &localStore)
    }.store(in: &store)

    // Union the inner Cancellation set
    store.formUnion(localStore)
    
    theme.$titleFont.sink { [weak self] font in
      self?.titleLabel?.font = font
    }.store(in: &store)
  }
}

// MARK: - Default Group Chat

extension MessageInputComponentTheme {
  public static var pubnubGroupChat: MessageInputComponentTheme {
    return MessageInputComponentTheme(
      viewType: MessageInputBarComponent.self,
      backgroundColor: .secondarySystemBackground,
      placeholderText: "Type Message",
      placeholderTextColor: .systemGray2,
      placeholderTextFont: AppearanceTemplate.Font.body,
      textInputTheme: .pubnubGroupChat,
      sendButton: .pubnubGroupChat,
      typingIndicatorService: .shared,
      publishTypingIndicator: true,
      displayTypingIndicator: true
    )
  }
}

extension InputTextViewComponentTheme {
  public static var pubnubGroupChat: InputTextViewComponentTheme {
    return InputTextViewComponentTheme(
      customType: UITextView.self,
      backgroundColor: .tertiarySystemBackground,
      textColor: .systemGray2,
      textFont: AppearanceTemplate.Font.body,
      usesStandardTextScaling: true,
      dataDetectorTypes: .all,
      linkTextAttributes: [:],
      isEditable: true,
      isExclusiveTouch: false,
      scrollView: .enabled,
      textContainerInset: .zero,
      typingAttributes: [:],
      autocapitalizationType: .sentences,
      autocorrectionType: .default,
      spellCheckingType: .default,
      smartQuotesType: .default,
      smartDashesType: .default,
      smartInsertDeleteType: .default,
      keyboardType: .default,
      keyboardAppearance: .default,
      textContentType: nil
    )
  }
}

extension ButtonComponentTheme {
  public static var pubnubGroupChat: ButtonComponentTheme {
    return ButtonComponentTheme(
      backgroundColor: .clear,
      buttonType: .custom,
      tintColor: .systemBlue,
      title: .empty,
      titleHighlighted: .empty,
      titleFont: AppearanceTemplate.Font.caption1,
      image: ButtonImageStateTheme(
        image: AppearanceTemplate.Image.messageSend?.withTintColor(.systemBlue),
        backgroundImage: nil
      ),
      imageHighlighted: .empty
    )
  }
}
