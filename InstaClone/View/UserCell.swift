//
//  UserCell.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

protocol UserCellDelegate: class{
    func userCell(_ cell: UserCell, wantsToShowUserProfile user: User)
}

//searchControllerで使われる。
class UserCell: UITableViewCell {
    
    // MARK: - Properties
    
    var viewModel: UserCellViewModel? {   //cell生成時にuserオブジェクトを使ってviewModelが作られ、それがここに代入される。
        didSet { configure() }
    }
    weak var delegate: UserCellDelegate?
    
    private lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImageOrName))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tap)
        return iv
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImageOrName))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
        return label
    }()
    
    private lazy var fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImageOrName))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
        return label
    }()
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(profileImageView)  //直近のiOS以降、contentViewにaddSubViewしないとgesture機能が伝わらないので要注意。
        profileImageView.setDimensions(height: 48, width: 48)
        profileImageView.layer.cornerRadius = 48 / 2
        profileImageView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 12)
        
        let stack = UIStackView(arrangedSubviews: [usernameLabel, fullnameLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        
        contentView.addSubview(stack)
        stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 8)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    func configure() {
        guard let viewModel = viewModel else { return }
        
        profileImageView.sd_setImage(with: viewModel.profileImageUrl)
        usernameLabel.text = viewModel.username
        fullnameLabel.text = viewModel.fullname
    }
    
    @objc func didTapImageOrName(){
        guard let viewModel = viewModel else { return }
        
        delegate?.userCell(self, wantsToShowUserProfile: viewModel.user)
        
    }
}
