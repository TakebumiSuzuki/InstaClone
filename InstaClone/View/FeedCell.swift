//
//  FeedCell.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit
import ActiveLabel

protocol FeedCellDelegate: class {
    func cell(_ cell: FeedCell, wantsToShowCommentsFor post: Post, image: UIImage, caption: String)
    func cell(_ cell: FeedCell, didLike post: Post)
    func cell(_ cell: FeedCell, wantsToShowProfileFor uid: String)
    func cell(_ cell: FeedCell, wantsToViewLikesFor postId: String)
    func cell(_ cell: FeedCell, wantsToShowOptionsForPost post: Post)
    func cell(_ cell: FeedCell, wantsToShare image: UIImage, caption: String)
}


//shareButton(折り紙飛行機)のタップアクションが定義されていない
class FeedCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    //ポイントはFeedController上で cell.viewModel?.post.ownerUsername = "test" などとやるとpostとシンクロして
    //viewModelが更新され、その結果、didSetが起動し、UIも連動して更新されるという事。自動アップデートができる。
    //これは即席でcell上のUIを変化させるのに使える。根本的にはグローバルの[Post]をアップデートする必要がある(dequeueに対応する為)。
    var viewModel: PostViewModel? {  //viewModelはcellが作られる時に、postを使って作られ、同時に代入される
        didSet { configure() }
    }
    weak var delegate: FeedCellDelegate?
    
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        iv.isUserInteractionEnabled = true   //これがないと下のTapGestureが効かない。
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showUserProfile))
        iv.addGestureRecognizer(tap)
        return iv
    }()
    
    private lazy var usernameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        button.addTarget(self, action: #selector(showUserProfile), for: .touchUpInside)
        return button
    }()
    
    private lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)   //ellipsisは3つの点が並ぶ画像
        button.tintColor = .black
        button.addTarget(self, action: #selector(showOptions), for: .touchUpInside)
        return button
    }()
    
    private let postImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(didTapLike), for: .touchUpInside)
        return button
    }()
    
    private lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "comment"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(didTapComments), for: .touchUpInside)
        return button
    }()
    
    private lazy var shareButton: UIButton = {  //このshareButtonにアクションをつけ忘れている。
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send2"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
        return button
    }()
    
    private lazy var  likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLikesTapped))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
        return label
    }()
    
    lazy var captionLabel: ActiveLabel = {  //ActiveLableについては調べる必要あり
        let label = ActiveLabel()   //viewModel側の設定で、usernameとcaptionを続けて表示するようにしている。
        label.numberOfLines = 2
//        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapComments))
//        label.isUserInteractionEnabled = true
//        label.addGestureRecognizer(tap)
        return label
    }()
    
    private let postTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        return label
    }()
        
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor,
                                paddingTop: 12, paddingLeft: 12)
        profileImageView.setDimensions(height: 40, width: 40)
        profileImageView.layer.cornerRadius = 40 / 2
        
        addSubview(usernameButton)
        usernameButton.centerY(inView: profileImageView,
                               leftAnchor: profileImageView.rightAnchor, paddingLeft: 8)
        
        addSubview(optionsButton)
        optionsButton.centerY(inView: profileImageView)
        optionsButton.anchor(right: rightAnchor, paddingRight: 12)
        
        addSubview(postImageView)
        postImageView.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor,
                             paddingTop: 8)
        postImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        
        configureActionButtons()
        
        addSubview(likesLabel)
        likesLabel.anchor(top: likeButton.bottomAnchor, left: leftAnchor, paddingTop: -8,
                          paddingLeft: 10)
        
        addSubview(captionLabel)
        captionLabel.anchor(top: likesLabel.bottomAnchor, left: leftAnchor, right: rightAnchor,
                            paddingLeft: 10, paddingRight: 10)
        
        addSubview(postTimeLabel)
        postTimeLabel.anchor(top: captionLabel.bottomAnchor, left: leftAnchor, paddingLeft: 10)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Helpers
    
    func configureActionButtons() {
        
        let stackView = UIStackView(arrangedSubviews: [likeButton, commentButton, shareButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        stackView.anchor(top: postImageView.bottomAnchor, left: leftAnchor, paddingLeft: 0, width: 120, height: 50)
    }
    
    func configure() {  //cellが生成されてその後ViewModelが代入されるとdidSetでここが呼ばれる。また、postオブジェクトが更新された時にも。
        guard let viewModel = viewModel else { return }
        
        profileImageView.sd_setImage(with: viewModel.userProfileImageUrl)
        usernameButton.setTitle(viewModel.username, for: .normal)
        postImageView.sd_setImage(with: viewModel.imageUrl)
        likeButton.tintColor = viewModel.likeButtonTintColor
        likeButton.setImage(viewModel.likeButtonImage, for: .normal)
        likesLabel.text = viewModel.likesLabelText
        
        captionLabel.configureLinkAttribute = viewModel.configureLinkAttribute
        captionLabel.enabledTypes = viewModel.enabledTypes
        viewModel.customizeLabel(captionLabel)  //このファンクションでコメントを埋め込むかと。
        
        postTimeLabel.text = "\(viewModel.timestampString!) ago"
    }
    
    
    // MARK: - Actions
    
    @objc func didTapShare() {
        guard let image = postImageView.image else { return }
        guard let caption = captionLabel.text else { return }
        delegate?.cell(self, wantsToShare: image, caption: caption)
    }
    
    @objc func showUserProfile() {
        guard let viewModel = viewModel else { return }
        delegate?.cell(self, wantsToShowProfileFor: viewModel.post.ownerUid)
    }
    
    @objc func showOptions() {
        guard let viewModel = viewModel else { return }
        delegate?.cell(self, wantsToShowOptionsForPost: viewModel.post)
    }
    @objc func didTapComments() {
        guard let viewModel = viewModel else { return }
        guard let image = postImageView.image else { return }
        guard let caption = captionLabel.text else { return }
        delegate?.cell(self, wantsToShowCommentsFor: viewModel.post, image: image, caption: caption)
    }
    
    @objc func didTapLike() {
        guard let viewModel = viewModel else { return }
        delegate?.cell(self, didLike: viewModel.post)
    }
    
    @objc func handleLikesTapped() {
        guard let viewModel = viewModel else { return }
        delegate?.cell(self, wantsToViewLikesFor: viewModel.post.postId)

    }
    

    
    
}
