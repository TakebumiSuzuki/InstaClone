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
    
    var customLabelType: ActiveType {   //caption一番左に表示される投稿者自身のusernameを太字にする為にカスタムとして扱っている。
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
                atts[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 14)
            }
            return atts
        }
    }
    func customizeLabel(_ label: ActiveLabel) {
        label.customize { label in
            label.text = "\(username)  \(caption)"     //ここでusernameとcaptionが使われている。
            label.customColor[customLabelType] = .black
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .black
        }
    }
    
    var timestampString: String? {
        TimestampService.getStringDate(timeStamp: post.timestamp, unitsStyle: .full)
    }
    
}
