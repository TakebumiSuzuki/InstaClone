//
//  Comment.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Firebase

struct Comment {  //Firestorage内でPostコレクションの中のpostドキュメント下に置かれる
    let uid: String
    let username: String
    let profileImageUrl: String
    let commentText: String
    let postOwnerUid: String
    let timestamp: Timestamp
    
    init(dictionary: [String: Any]) {
        self.uid = dictionary["uid"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        self.commentText = dictionary["comment"] as? String ?? ""
        self.postOwnerUid = dictionary["postOwnerUid"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}
