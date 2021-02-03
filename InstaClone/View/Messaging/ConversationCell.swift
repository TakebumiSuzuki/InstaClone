//
//  ConversationCell.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

class ConversationCell: UITableViewCell {
    
    // MARK: - Properties
    
    var viewModel: MessageViewModel? {  //チャットページと同じviewModelを共用しているが、こちらでは数個のプロパティのみ使用している。
        didSet { configure() }
    }
    
    let chatPartnerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    let chatPartnerNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    let messageTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.text = "2h"
        return label
    }()
    
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        addSubview(chatPartnerImageView)
        chatPartnerImageView.anchor(left: leftAnchor, paddingLeft: 12)
        chatPartnerImageView.setDimensions(height: 50, width: 50)
        chatPartnerImageView.layer.cornerRadius = 50 / 2
        chatPartnerImageView.centerY(inView: self)
        
        let stack = UIStackView(arrangedSubviews: [chatPartnerNameLabel, messageTextLabel])
        stack.axis = .vertical
        stack.spacing = 4
        
        addSubview(stack)
        stack.centerY(inView: chatPartnerImageView)
        stack.anchor(left: chatPartnerImageView.rightAnchor, right: rightAnchor, paddingLeft: 12, paddingRight: 16)
        
        addSubview(timestampLabel)
        timestampLabel.anchor(top: topAnchor, right: rightAnchor, paddingTop: 20, paddingRight: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Helpers
    
    func configure() {
        guard let viewModel = viewModel else { return }
        
        chatPartnerImageView.sd_setImage(with: viewModel.chatPartnerImageUrl)
        chatPartnerNameLabel.text = viewModel.chatPartnerName
        messageTextLabel.text = viewModel.messageText
        timestampLabel.text = viewModel.timestampString
    }
}
