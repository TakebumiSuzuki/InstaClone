//
//  MessageCell.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit
import Firebase


class MessageCell: UICollectionViewCell {

    // MARK: - Properties
    
    //messageを引数としてインスタンス化され、ここに代入される。また、override initが先に全部実行された後にこちらが実行される。
    var viewModel: MessageViewModel? {
        didSet { configure() }
    }

    var bubbleLeftAnchor: NSLayoutConstraint!
    var bubbleRightAnchor: NSLayoutConstraint!

    let dateCellHeader: UITextField = {
        let tf = UITextField()
        tf.textAlignment = .center
        tf.font = UIFont.systemFont(ofSize: 12)
        tf.textColor = .systemGray
        return tf
    }()
    
    private let profileImageView: UIImageView = {  //これのisHiddenプロパティはviewModelによって処理される
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let bubbleContainer: UIView = {  //これのbackgroundcolor, boarderwidth, constraintはviewModelによって処理される
        let view = UIView()
//        view.backgroundColor = .systemPurple //これは結局configure()で上書きされるのでコメントアウトでもok
        return view   //これの中にsubViewとしてtextViewが入る。
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.isEditable = false
        tv.font = .systemFont(ofSize: 16)
        tv.textColor = .black
        return tv
    }()

    
    // MARK: - Lifecycle

    override init(frame: CGRect) {  //UICollectionViewCellの中のcontentViewの仕組みがまだ完全にわかっていない
        super.init(frame: frame)
        
        addSubview(dateCellHeader)
        dateCellHeader.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, height: 20)
        
        addSubview(profileImageView)  //paddingBottomが-4な為、わずかにプロフィール丸画像が下にずれる。
        //ちなみに、ここでself.clipsToBounds = trueとすると、丸画像の下が切れる。
        profileImageView.anchor(left: leftAnchor, bottom: bottomAnchor, paddingLeft: 12, paddingBottom: -4)
        profileImageView.setDimensions(height: 36, width: 36)
        profileImageView.layer.cornerRadius = 36 / 2
        
        addSubview(bubbleContainer)
        bubbleContainer.layer.cornerRadius = 11
        bubbleContainer.anchor(top: dateCellHeader.bottomAnchor, bottom: bottomAnchor, paddingTop: 0)
        bubbleContainer.widthAnchor.constraint(lessThanOrEqualToConstant: self.frame.width*3/5).isActive = true
        
        //以下のbubbleコンテナーの左右のconstraintのisActiveはviewModelによって処理される
        bubbleLeftAnchor = bubbleContainer.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 12)
        bubbleLeftAnchor.isActive = false

        bubbleRightAnchor = bubbleContainer.rightAnchor.constraint(equalTo: rightAnchor, constant: -12)
        bubbleRightAnchor.isActive = false

        bubbleContainer.addSubview(textView)
        textView.anchor(top: bubbleContainer.topAnchor, left: bubbleContainer.leftAnchor,
                        bottom: bubbleContainer.bottomAnchor, right: bubbleContainer.rightAnchor,
                        paddingTop: 2, paddingLeft: 12, paddingBottom: 2, paddingRight: 12)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // MARK: - Helpers

    func configure() {
        guard let viewModel = viewModel else { return }

        profileImageView.sd_setImage(with: viewModel.chatPartnerImageUrl)
        textView.text = viewModel.messageText
        
        dateCellHeader.text = viewModel.timestampString
        
        bubbleContainer.backgroundColor = viewModel.messageBackgroundColor
        bubbleContainer.layer.borderWidth = viewModel.messageBorderWidth
        bubbleContainer.layer.borderColor = UIColor.lightGray.cgColor
        
        profileImageView.isHidden = viewModel.shouldHideProfileImage
        bubbleLeftAnchor.isActive = viewModel.leftAnchorActive
        bubbleRightAnchor.isActive = viewModel.rightAnchorActive
    }
}
