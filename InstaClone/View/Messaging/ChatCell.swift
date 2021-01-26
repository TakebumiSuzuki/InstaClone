//
//  ChatChell.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit
import Firebase

//timestampを入れ忘れているので、自分で入れてみる事。
class MessageCell: UICollectionViewCell {

    // MARK: - Properties
    
    //messageを引数にインスタンス化され、ここに代入される。また、override initが先に全部実行された後にこちらが実行される。
    var viewModel: MessageViewModel? {
        didSet { configure() }
    }

    var bubbleLeftAnchor: NSLayoutConstraint!
    var bubbleRightAnchor: NSLayoutConstraint!

    private let profileImageView: UIImageView = {  //これのisHiddenプロパティはviewModelによって処理される
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let bubbleContainer: UIView = {  //これのbackgroundcolor, boarderwidth, constraintはviewModelによって処理される
        let view = UIView()
        view.backgroundColor = .systemPurple //これは結局configure()で上書きされるのでコメントアウトでもok
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

    override init(frame: CGRect) {  //UICollectionViewCellの中のcontentViewの仕組みがまだわかっていない
        super.init(frame: frame)
        
        addSubview(profileImageView)  //paddingBottomが-4な為、わずかにプロフィール丸画像が下にずれる。
        //ちなみに、self.clipsToBounds = trueとすると、丸画像の下が切れる。
        profileImageView.anchor(left: leftAnchor, bottom: bottomAnchor, paddingLeft: 8, paddingBottom: -4)
        profileImageView.setDimensions(height: 32, width: 32)
        profileImageView.layer.cornerRadius = 32 / 2
        
//        addSubview(bubbleContainer)
//        bubbleContainer.layer.cornerRadius = 12  //この2行多分いらないのでコメントアウトする。

        addSubview(bubbleContainer)
        bubbleContainer.layer.cornerRadius = 12
        bubbleContainer.anchor(top: topAnchor, bottom: bottomAnchor)
        bubbleContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 250).isActive = true
        
        //以下のbubbleコンテナーの左右のconstraintのisActiveはviewModelによって処理される
        bubbleLeftAnchor = bubbleContainer.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 12)
        bubbleLeftAnchor.isActive = false

        bubbleRightAnchor = bubbleContainer.rightAnchor.constraint(equalTo: rightAnchor, constant: -12)
        bubbleRightAnchor.isActive = false

        bubbleContainer.addSubview(textView)
        textView.anchor(top: bubbleContainer.topAnchor, left: bubbleContainer.leftAnchor,
                        bottom: bubbleContainer.bottomAnchor, right: bubbleContainer.rightAnchor,
                        paddingTop: 4, paddingLeft: 12, paddingBottom: 4, paddingRight: 12)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    // MARK: - Helpers

    func configure() {
        guard let viewModel = viewModel else { return }

        bubbleContainer.backgroundColor = viewModel.messageBackgroundColor
        bubbleContainer.layer.borderWidth = viewModel.messageBorderWidth
        bubbleContainer.layer.borderColor = UIColor.lightGray.cgColor
        textView.text = viewModel.messageText

        bubbleLeftAnchor.isActive = viewModel.leftAnchorActive
        bubbleRightAnchor.isActive = viewModel.rightAnchorActive

        profileImageView.isHidden = viewModel.shouldHideProfileImage
        profileImageView.sd_setImage(with: viewModel.profileImageUrl)
    }
}
