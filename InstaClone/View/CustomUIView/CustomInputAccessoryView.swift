//
//  CustomInputAccessoryView.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

protocol CustomInputAccesoryViewDelegate: class {
    func inputView(_ inputView: CustomInputAccesoryView, wantsToUploadText text: String)
}

enum InputViewConfiguration {
    case comments
    case messages
    
    var placeholderText: String {
        switch self {
        case .comments: return "Comment..."
        case .messages: return "Message..."
        }
    }
    
    var actionButtonTitle: String {
        switch self {
        case .comments: return "Post"
        case .messages: return "Send"
        }
    }
}

class CustomInputAccesoryView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: CustomInputAccesoryViewDelegate?
    
    private let config: InputViewConfiguration
            
    lazy var commentTextView: InputTextView = {
        let tv = InputTextView()
        tv.placeholderText = config.placeholderText
        tv.font = UIFont.systemFont(ofSize: 15)
        tv.isScrollEnabled = false
        tv.placeholderShouldCenter = true
        return tv
    }()
    
    private lazy var postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(config.actionButtonTitle, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handlePostTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    init(config: InputViewConfiguration, frame: CGRect) {
        self.config = config
        super.init(frame: frame)
        
        backgroundColor = .white  //これがないと透明な為、一番下の部分が透けてしまう。
        autoresizingMask = .flexibleHeight
        
        addSubview(postButton)
        postButton.anchor(top: topAnchor, right: rightAnchor, paddingRight: 8)
        postButton.setDimensions(height: 50, width: 50)
        
        addSubview(commentTextView)
        commentTextView.anchor(top: topAnchor, left: leftAnchor,
                               bottom: safeAreaLayoutGuide.bottomAnchor, right: postButton.leftAnchor,
                               paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8)
        
        let divider = UIView()
        divider.backgroundColor = .lightGray
        addSubview(divider)
        divider.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //詳細不明
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    // MARK: - Actions
    
    @objc func handlePostTapped() {
        delegate?.inputView(self, wantsToUploadText: commentTextView.text)
    }
    
    // MARK: - Helpers
    
    func clearInputText() {
        commentTextView.text = nil
        commentTextView.placeholderLabel.isHidden = false
    }
}
