//
//  AddMessageReactionComponent.swift
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

import UIKit
import Combine

/// Protocol for each class that can serve as an emoji picker view.
///
/// Subclasses should adopt the `completer` variable and publish an emoji value that was selected by the user
public protocol AnyMessageReactionComponent {
  var selectedReactionValue: AnyPublisher<String, Never> { get }
}

open class AddMessageReactionComponent: UIViewController, AnyMessageReactionComponent {

  private var reactionList: [String]
  private var pickerView: UIView & AnyMessageReactionComponent
  private var cancellables = Set<AnyCancellable>()

  init(
    pickerView view: UIView & AnyMessageReactionComponent,
    reactionList list: [String]
  ) {
    pickerView = view
    reactionList = list
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required public init?(coder: NSCoder) {
    preconditionFailure("Use init(with:) instead")
  }
  
  public var selectedReactionValue: AnyPublisher<String, Never> {
    pickerView.selectedReactionValue
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
            
    view.addSubview(pickerView)
    
    NSLayoutConstraint.activate([
        pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        pickerView.widthAnchor.constraint(equalTo: view.widthAnchor),
        pickerView.heightAnchor.constraint(equalTo: view.heightAnchor)
      ]
    )
  }
  
  final class DefaultPickerView: UIStackContainerView, AnyMessageReactionComponent {
    
    private let reactionList: [String]
    private let selectedReactionSubject: PassthroughSubject<String, Never>
    
    init(reactionList list: [String]) {
      
      reactionList = list
      selectedReactionSubject = PassthroughSubject<String, Never>()
      
      super.init(frame: .zero)
    }
    
    public required init?(coder: NSCoder) {
      preconditionFailure("Use init(with:) instead")
    }
    
    var selectedReactionValue: AnyPublisher<String, Never> {
      selectedReactionSubject.eraseToAnyPublisher()
    }
    
    override func setupSubviews() {
      super.setupSubviews()
      
      layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
      backgroundColor = .lightGray
      layer.cornerRadius = 20
      
      stackView.alignment = .center
      stackView.axis = .horizontal
      stackView.spacing = 10
      stackView.distribution = .fillEqually
      
      reactionList.enumerated().forEach() { index, value in
        
        let buttonView = UIButton(type: .custom)
        buttonView.tag = index
        buttonView.setTitle(value, for: .normal)
        buttonView.titleLabel?.font = AppearanceTemplate.Font.largeTitle
        buttonView.sizeToFit()
        buttonView.addTarget(self, action: #selector(onButtonTapped(_:)), for: .touchUpInside)
        
        stackView.addArrangedSubview(buttonView)
      }
    }
    
    @objc
    func onButtonTapped(_ sender: UIButton) {
      selectedReactionSubject.send(reactionList[sender.tag])
      selectedReactionSubject.send(completion: .finished)
    }
  }
}
