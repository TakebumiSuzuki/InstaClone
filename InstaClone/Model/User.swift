//
//  User.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Foundation
import Firebase

class User {
    
    let email: String
    var fullname: String
    var profileImageUrl: String
    var username: String
    let uid: String
    var isCurrentUser: Bool { return Auth.auth().currentUser?.uid == uid }
    
    var isFollowed = false  //このuserをcurrentUserがフォローしているかどうかを後付けで入れる。
    var stats: UserStats!  //なぜ!マークをつけているのか不明。イニシャライズ時は(0,0,0)で情報を入れ、実際は後付け
    
    let fcmToken: String
    
    init(dictionary: [String: Any]) {
        self.email = dictionary["email"] as? String ?? ""
        self.fullname = dictionary["fullname"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
        self.fcmToken = dictionary["fcmToken"] as? String ?? ""
        
        self.stats = UserStats(followers: 0, following: 0, posts: 0)
    }
}

struct UserStats {
    var followers: Int
    let following: Int
    let posts: Int
}
