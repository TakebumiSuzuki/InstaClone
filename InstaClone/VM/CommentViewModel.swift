//
//  CommentViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

struct CommentViewModel {
    
    let comment: Comment
    init(comment: Comment) {
        self.comment = comment
    }
    
    var profileImageUrl: URL? { return URL(string: comment.profileImageUrl) }
    
    var timeStamp: String {
        let time = TimestampService.getStringDate(timeStamp: comment.timestamp, unitsStyle: .abbreviated) ?? ""
        return time
    }
    
    func commentLabelText() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "\(comment.username)  ", attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedString.append(NSAttributedString(string: comment.commentText, attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        return attributedString
    }
    
    func sizeEstimate(forWidth width: CGFloat) -> CGSize {  //ここで仮想のUILabelを作って高さを測定している。
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = self.commentLabelText()
        label.lineBreakMode = .byWordWrapping
        label.setWidth(width)  //extension。UIViewに対して任意のwithのconstraintを適用するメソッド
        return label.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)  //ここはまだ不明
    }
}
