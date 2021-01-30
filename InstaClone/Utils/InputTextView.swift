//
//  InputTextView.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit
//このカスタムサブクラスはUploadPostControllerと、多分チャットやコメント機能のコントローラーからも使われる。
//UITextViewにはないplaceHolderのUILabelを加え、そのconstraintを選択できるようにするのがこのカスタムサブクラスの目的。
class InputTextView: UITextView {
    
    // MARK: - Properties
    
    var placeholderText: String? {
        didSet { placeholderLabel.text = placeholderText }
    }
    
    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        return label
    }()
    
    var placeholderShouldCenter = true {  //placeholderの位置を２バージョン。どちらでも選択できるように。
        didSet {
            if placeholderShouldCenter {  //verticallyに真ん中になるように
                placeholderLabel.anchor(left: leftAnchor, right: rightAnchor, paddingLeft: 8)
                placeholderLabel.centerY(inView: self)
            } else {  //上左からピンする
                placeholderLabel.anchor(top: topAnchor, left: leftAnchor, paddingTop: 6, paddingLeft: 8)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect, textContainer: NSTextContainer?) { //この正式イニシャライザは使っていない。NSTextContainerについて不明。
        super.init(frame: frame, textContainer: textContainer)
        
        addSubview(placeholderLabel)
        
        //以下はUITextViewオブジェクトが自動ポストするnotification。知らないと書けないコード。textFieldでも同様のものが存在する。
        //機能的にはUITextViewDelegateのdidChangeと同等。下にあるplacehalderLabel.isHiddenをコントロールする。
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextDidChange),
                                               name: UITextView.textDidChangeNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    @objc func handleTextDidChange() {  //textViewの中身が空の時のみplaceholerを表示する
        placeholderLabel.isHidden = !text.isEmpty
    }
}
