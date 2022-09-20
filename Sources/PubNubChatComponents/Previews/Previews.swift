//
//  File 2.swift
//  
//
//  Created by Jakub Guz on 9/14/22.
//

import PubNub
import PubNubChat
import CoreData
import Combine
import UIKit
import SwiftUI
import ChatLayout

#if canImport(SwiftUI) && DEBUG

struct ExamplePreview: PreviewProvider {
  
  static var previews: some View {
    
    Group() {
      
      // Light Mode
      UIViewPreview() {
        let view = MessageListItemCell()
        view.configure(MyViewModel(), theme: .incomingGroupChat)
        return view
      }
      .previewLayout(.fixed(width: 414, height: 140))
      .previewDisplayName("Light Mode")
      .preferredColorScheme(.light)
      
      // Dark Mode
      UIViewPreview() {
        let view = MessageListItemCell()
        view.configure(MyViewModel(), theme: .incomingGroupChat)
        return view
      }
      .previewLayout(.fixed(width: 414, height: 140))
      .previewDisplayName("Dark Mode")
      .preferredColorScheme(.dark)
      
      // RTL
      UIViewPreview() {
        let view = MessageListItemCell()
        view.configure(MyViewModel(), theme: .incomingGroupChat)
        return view
      }
      .environment(\.layoutDirection, .rightToLeft)
      .previewLayout(.fixed(width: 414, height: 140))
      .previewDisplayName("RTL")
      
      // Accessibility
      UIViewPreview() {
        
        let view = MessageListItemCell()
        view.configure(MyViewModel(), theme: .incomingGroupChat)
        return view
      }
      .environment(\.sizeCategory, .accessibilityExtraLarge)
      .previewLayout(.fixed(width: 414, height: 140))
      .previewDisplayName("Accessibility")
      
      UIViewControllerPreview() {
        let vm = testChatProvider.senderMembershipsChanneListComponentViewModel()
        let vc = vm.configuredComponentView()
        let navv = UINavigationController(rootViewController: vc)
        
        return navv
      }
      .previewDisplayName("VC")
      
      if #available(iOS 15.0, *) {
        UIViewControllerPreview() {
          let vm = testChatProvider.senderMembershipsChanneListComponentViewModel()
          let vc = vm.configuredComponentView()
          let navv = UINavigationController(rootViewController: vc)
          
          return navv
          
        }
        .previewInterfaceOrientation(.landscapeRight)
        .previewDisplayName("VC2")
      } else {
        // Fallback on earlier versions
      }
    }
  }
}

#endif
