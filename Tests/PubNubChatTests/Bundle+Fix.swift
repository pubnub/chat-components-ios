//
//  Bundle+Fix.swift
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

import PubNubChat

// This workaround comes from Skyler_s and Nekitosss on <https://developer.apple.com/forums/thread/664295>
public let localBundle = Bundle.fixedModule

private final class CurrentBundleFinder {}

private let packageName: String = "chat-components-ios"
private let targetName: String = "PubNubChat"

extension Foundation.Bundle {
  
  /// Returns the resource bundle associated with the current Swift module.
  ///
  /// # Notes: #
  /// 1. This is inspired by the `Bundle.module` declaration
  static var fixedModule: Bundle = {
    // The name of your local package, prepended by "LocalPackages_" for iOS and "PackageName_" for macOS
    // You may have same PackageName and TargetName
    let bundleNameIOS = "LocalPackages_\(targetName)"
    let bundleNameMacOs = "\(packageName)_\(targetName)"
    
    let candidates = [
      // Bundle should be present here when the package is linked into an App.
      Bundle.main.resourceURL,
      
      // Bundle should be present here when the package is linked into a framework.
      Bundle(for: CurrentBundleFinder.self).resourceURL,
      
      // For command-line tools.
      Bundle.main.bundleURL,
      
      // Bundle should be present here when running previews from a different package
      // (this is the path to "…/Debug-iphonesimulator/").
      Bundle(for: CurrentBundleFinder.self).resourceURL?
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
      Bundle(for: CurrentBundleFinder.self).resourceURL?
        .deletingLastPathComponent().deletingLastPathComponent(),
    ]
    
    for candidate in candidates {
      let bundlePathiOS = candidate?.appendingPathComponent(bundleNameIOS + ".bundle")
      let bundlePathMacOS = candidate?.appendingPathComponent(bundleNameMacOs + ".bundle")
      if let bundle = bundlePathiOS.flatMap(Bundle.init(url:)) {
        return bundle
      } else if let bundle = bundlePathMacOS.flatMap(Bundle.init(url:)) {
        return bundle
      }
    }
    
    return Bundle(for: CoreDataProvider.self)
  }()
  
}
