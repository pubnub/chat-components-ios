//
//  AppearanceTemplate.swift
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
import UIKit

import PubNubChat
import PubNub

// StyleProvider
public struct AppearanceTemplate {
  
  // Dyanmic System Colors: https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/
  // Full List: https://developer.apple.com/documentation/uikit/uicolor/ui_element_colors
  public struct Color {
    public static var background: UIColor = UIColor(named: "background") ?? .systemBackground
    public static var secondaryBackground: UIColor = UIColor(named: "secondaryBackground") ?? .secondarySystemBackground
    public static var tertiaryBackground: UIColor = UIColor(named: "tertiaryBackground") ?? .tertiarySystemBackground

    public static var groupedBackground: UIColor = UIColor(named: "groupedBackground") ?? .systemGroupedBackground
    public static var secondaryGroupedBackground: UIColor = UIColor(named: "secondaryGroupedBackground") ?? .secondarySystemGroupedBackground
    public static var tertiaryGroupedBackground: UIColor = UIColor(named: "tertiaryGroupedBackground") ?? .tertiarySystemGroupedBackground
    
    public static var label: UIColor = UIColor(named: "label") ?? .label
    public static var secondaryLabel: UIColor = UIColor(named: "secondaryLabel") ?? .secondaryLabel
    public static var tertiaryLabel: UIColor = UIColor(named: "tertiaryLabel") ?? .tertiaryLabel
    public static var quaternaryLabel: UIColor = UIColor(named: "quaternaryLabel") ?? .quaternaryLabel
    
    public static var fill: UIColor = UIColor(named: "fill") ?? .systemFill
    public static var secondaryFill: UIColor = UIColor(named: "secondaryFill") ?? .secondarySystemFill
    public static var tertiaryFill: UIColor = UIColor(named: "tertiaryFill") ?? .tertiarySystemFill

    public static var separator: UIColor = UIColor(named: "separator") ?? .separator
    public static var opaqueSeparator: UIColor = UIColor(named: "opaqueSeparator") ?? .opaqueSeparator
    
    public static var messageActionActive: UIColor = UIColor(named: "messageActionActive") ??  UIColor(0xef3a43, alpha: 0.24)
  }
  
  // Dynamic Type Sizes https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/typography/
  public struct Font {
    public static var largeTitle: UIFont = UIFont.preferredFont(forTextStyle: .largeTitle)
    
    public static var title1: UIFont = UIFont.preferredFont(forTextStyle: .title1)
    public static var title2: UIFont = UIFont.preferredFont(forTextStyle: .title2)
    public static var title3: UIFont = UIFont.preferredFont(forTextStyle: .title3)

    public static var headline: UIFont = UIFont.preferredFont(forTextStyle: .headline)
    public static var subheadline: UIFont = UIFont.preferredFont(forTextStyle: .subheadline)

    public static var body: UIFont = UIFont.preferredFont(forTextStyle: .body)

    public static var callout: UIFont = UIFont.preferredFont(forTextStyle: .callout)

    public static var footnote: UIFont = UIFont.preferredFont(forTextStyle: .footnote)

    public static var caption1: UIFont = UIFont.preferredFont(forTextStyle: .caption1)
    public static var caption2: UIFont = UIFont.preferredFont(forTextStyle: .caption2)
  }
  
  // Sytem Icons https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/system-icons/
  public struct Image {
    public static var add: UIImage? = UIImage(named: "add") ?? UIImage(systemName: "plus")
    public static var refresh: UIImage? = UIImage(named: "refresh") ?? UIImage(systemName: "arrow.clockwise")
    public static var send: UIImage? = UIImage(named: "send") ?? UIImage(systemName: "arrow.up.circle.fill")
    
    public static var avatar: UIImage? = UIImage(named: "avatar") ?? UIImage(systemName: "circle.fill")
    
    public static var members: UIImage? = UIImage(named: "members") ?? UIImage(systemName: "person.2")
    
    public static var messageSend: UIImage? = UIImage(named: "messageSend") ?? UIImage(systemName: "paperplane.fill")?.rotate(degree: 45)
    
  }
  
  public init() {}
  
  public static var shared = AppearanceTemplate()

}

extension UIColor {
  static func adaptiveColor(light: UIColor, dark: UIColor) -> UIColor {
    return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
  }
  
  static func adaptiveColor(
    _ lightHex: Int, lightAlpha: CGFloat = 1.0,
    _ darkhex: Int, darkAlpha: CGFloat = 1.0
  ) -> UIColor {
    return adaptiveColor(
      light: UIColor(lightHex, alpha: lightAlpha),
      dark: UIColor(darkhex, alpha: lightAlpha)
    )
  }
}
