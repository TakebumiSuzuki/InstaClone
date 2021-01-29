//
//  PostViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

//ProfileControllerのページの下部でもこのVMは使われている。
//Postモデルで定義されているpostID変数はここでは使われていない。
import UIKit
import ActiveLabel

struct PostViewModel {
    
    var post: Post
    init(post: Post) {
        self.post = post
    }
    
    
    //以下の変数は全てpostオブジェクトからのcomputed propertyである事に気づくべき
    var username: String { return post.ownerUsername }
    var userProfileImageUrl: URL? { return URL(string: post.ownerImageUrl) }
    var imageUrl: URL? { return URL(string: post.imageUrl) }
    var likes: Int { return post.likes }
    
    var likeButtonTintColor: UIColor {
        return post.didLike ? .red : .black
    }
    var likeButtonImage: UIImage? {
        let imageName = post.didLike ? "like_selected" : "like_unselected"
        return UIImage(named: imageName)
    }
    var likesLabelText: String {
        if post.likes != 1 {
            return "\(post.likes) likes"
        } else {
            return "\(post.likes) like"
        }
    }
    
    var caption: String { return post.caption }
    
    var customLabelType: ActiveType {
        return ActiveType.custom(pattern: "^\(username)\\b")
    }
    var enabledTypes: [ActiveType] {
        return [.mention, .hashtag, .url, customLabelType]
    }
    var configureLinkAttribute: ConfigureLinkAttribute {
        return { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .custom:
                atts[NSAttributedString.Key.font] = UIFont.boldSystemFont(ofSize: 14)
            default: ()
            }
            return atts
        }
    }
    func customizeLabel(_ label: ActiveLabel) {
        label.customize { label in
            label.text = "\(username) \(caption)"     //ここでusernameとcaptionが使われている。
            label.customColor[customLabelType] = .black
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .black
            label.numberOfLines = 2
        }
    }
    
    var timestampString: String? {
        let formatter = DateComponentsFormatter()  //メモリ節約のためこれはグローバル変数またはstaticにするべきでは？
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full
        return formatter.string(from: post.timestamp.dateValue(), to: Date())
    }

    
}
