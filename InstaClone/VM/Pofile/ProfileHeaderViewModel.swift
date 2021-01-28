//
//  ProfileHeaderViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

//userを引数にinitされ、userの名前やフォロー数などの表示内容、following/followの切り替えロジックを行う。
struct ProfileHeaderViewModel {
    
    let user: User  //自分でも相手でも誰でも良いuserオブジェクト
    init(user: User) {
        self.user = user
    }
    
    
    var fullname: String { return user.fullname }
    
    var profileImageUrl: URL? { return URL(string: user.profileImageUrl) }
    
    
    
    var followButtonText: String {
        if user.isCurrentUser {   //userオブジェクトが自分自身である場合
            return "Edit Profile"
        }
        return user.isFollowed ? "Following" : "Follow"  //自分がuserをfollowしているかしていないか
    }
    
    var followButtonBackgroundColor: UIColor {
        return user.isCurrentUser ? .white : .systemBlue
    }
    
    var followButtonTextColor: UIColor {
        return user.isCurrentUser ? .black : .white
    }
    
    var numberOfFollowers: NSAttributedString {
        return attributedStatText(value: user.stats.followers, label: "followers")
    }
    
    var numberOfFollowing: NSAttributedString {
        return attributedStatText(value: user.stats.following, label: "following")
    }
    
    var numberOfPosts: NSAttributedString {
        return attributedStatText(value: user.stats.posts, label: "posts")
    }
    
    
    func attributedStatText(value: Int, label: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: "\(value)\n", attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: label, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        return attributedText
    }
}
