//
//  File.swift
//  
//
//  Created by Jakub Guz on 9/14/22.
//

#if canImport(SwiftUI) && DEBUG

import SwiftUI

struct UIViewPreview<View: UIView>: UIViewRepresentable {
  let view: View
  
  init(_ builder: @escaping () -> View) {
    view = builder()
  }
  
  func makeUIView(context: Context) -> UIView {
    return view
  }
  
  func updateUIView(_ view: UIView, context: Context) {
    view.setContentHuggingPriority(.defaultHigh, for: .vertical)
    view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
  }
}

struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
  let viewController: ViewController
  
  init(_ builder: @escaping () -> ViewController) {
    viewController = builder()
  }
  
  func makeUIViewController(context: Context) -> ViewController {
    viewController
  }
  
  func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    
  }
}

#endif
