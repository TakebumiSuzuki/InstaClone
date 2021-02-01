//
//  CommentViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

struct CommentViewModel {
    
    private let comment: Comment
    init(comment: Comment) {
        self.comment = comment
    }
    
    
    var profileImageUrl: URL? { return URL(string: comment.profileImageUrl) }
    
    var timeStamp: String {
//        let df = DateFormatter()
//        df.dateStyle = .short
//        let date = df.string(from: comment.timestamp.dateValue())
        let formatter = DateComponentsFormatter()  //メモリ節約のためこれはグローバル変数またはstaticにするべきでは？
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full
        return formatter.string(from: comment.timestamp.dateValue(), to: Date())!
        
    }
    
    
    func commentLabelText() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "\(comment.username)  ", attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedString.append(NSAttributedString(string: comment.commentText, attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        
        return attributedString
    }
    
    func size(forWidth width: CGFloat) -> CGSize {  //ここで仮想のUILabelを作って高さを測定している。
        let label = UILabel()
        label.numberOfLines = 0
        label.text = comment.commentText
        label.lineBreakMode = .byWordWrapping
        label.setWidth(width)  //extensionでUIViewに対してwithのconstraintを適用するメソッド
        return label.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)  //ここはまだ不明
    }
}
