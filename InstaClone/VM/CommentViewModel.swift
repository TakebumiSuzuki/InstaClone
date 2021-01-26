//
//  CommentViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

struct CommentViewModel {
    
    init(comment: Comment) {
        self.comment = comment
    }
    private let comment: Comment
    
    
    var profileImageUrl: URL? { return URL(string: comment.profileImageUrl) }
    
    
    func commentLabelText() -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString(string: "\(comment.username) ", attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedString.append(NSAttributedString(string: comment.commentText, attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        
        return attributedString
    }
    
    func size(forWidth width: CGFloat) -> CGSize {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = comment.commentText
        label.lineBreakMode = .byWordWrapping
        label.setWidth(width)  //extensionでUIViewに対してwithのconstraintを適用するメソッド
        return label.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)  //ここはまだ不明
    }
}
