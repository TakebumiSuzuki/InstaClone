//
//  CommentCell.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

protocol CommentCellDelegate: class{    //profileImageタップした時にプロフィール画面が出るように。
    func cell(_ cell: UICollectionViewCell, showUserProfileFor uid: String)
}

//commentLabelの外側のパッディングがどのように決まっているのか不明。上下の幅が広すぎる
class CommentCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var viewModel: CommentViewModel? {
        didSet { configure() }
    }
    
    weak var delegate: CommentCellDelegate?
    
    lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        
        iv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        iv.addGestureRecognizer(tap)
        return iv
    }()
    
    private let commentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemGray2
        return label
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(profileImageView)
        profileImageView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 12)
        profileImageView.setDimensions(height: 30, width: 30)
        profileImageView.layer.cornerRadius = 30 / 2
        
        addSubview(timeLabel)  //こちらのconstraintをcommentLabelより先に設定しないとエラーが出る。
        timeLabel.centerY(inView: self)
        timeLabel.anchor(right: rightAnchor,  paddingRight: 14)
        
        addSubview(commentLabel)
        commentLabel.centerY(inView: profileImageView,
                             leftAnchor: profileImageView.rightAnchor,
                             paddingLeft: 12)
        commentLabel.anchor(right: timeLabel.leftAnchor, paddingRight: 8)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    private func configure() {
        guard let viewModel = viewModel else { return }
        
        profileImageView.sd_setImage(with: viewModel.profileImageUrl)
        commentLabel.attributedText = viewModel.commentLabelText()
        timeLabel.text = "\(viewModel.timeStamp) ago"
    }
    
    @objc func profileImageTapped(){
        guard let viewModel = viewModel else{ return }
        
        let uid = viewModel.comment.uid
        delegate?.cell(self, showUserProfileFor: uid)
    }
    
}
