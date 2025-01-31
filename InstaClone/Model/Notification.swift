//
//  Notification.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Firebase

//Notificationの種類分別。like/follow/commentを分類する。
enum NotificationType: Int {
    case like  //ハートボタンを押した時に発信されるnotification
    case follow  //followした時
    case comment  //コメントした時
    
    var notificationMessage: String {  //notificationリストに表示するメッセージテキスト
        switch self {
        case .like:
            return " liked your post."
        case .follow:
            return " started following you."
        case .comment:
            return " commented on your post"
        }
    }
}

struct Notification {
    //受け手側のuidが含まれていない。なぜなら、Firestore内でuid別に保存場所を分けているから必要ない。
    let type: NotificationType
    let id: String  //firestoreアップロード時のドキュメントID(パス)
    let uid: String   //発信元(つまり自分)のuid
    let username: String       //発信元(つまり自分)のname
    let userProfileImageUrl: String  //発信元(つまり自分)のImageUrl
    let timestamp: Timestamp
    var postId: String?   //likeとcommentの時のみ値が入る。オプショナルなのでvar。
    var postImageUrl: String?  //likeとcommentの時のみ値が入る。オプショナルなのでvar。
    
    var userIsFollowed = false  //この変数はfirebaseに保存されることはなく、ローカル内でfetch直後に記入される
    
    
    init(dictionary: [String: Any]) {
        self.type = NotificationType(rawValue: dictionary["type"] as? Int ?? 0) ?? .like
        self.id = dictionary["id"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        self.userProfileImageUrl = dictionary["userProfileImageUrl"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.postId = dictionary["postId"] as? String ?? ""
        self.postImageUrl = dictionary["postImageUrl"] as? String ?? ""
    }
}
