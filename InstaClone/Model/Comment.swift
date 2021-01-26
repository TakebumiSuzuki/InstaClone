//
//  Comment.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Firebase

struct Comment {  //Post collectionの各post documentの下に置かれる
    
    let uid: String    //DidSelectItemAtメソッドで使う。また、いずれprofileImageやusernameを変更した時にcloud functionで更新する時に使える
    let username: String
    let profileImageUrl: String
    let timestamp: Timestamp  //使っていない
    let commentText: String
    let postOwnerUid: String
    
    
    init(dictionary: [String: Any]) {
        self.uid = dictionary["uid"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        self.commentText = dictionary["comment"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.postOwnerUid = dictionary["postOwnerUid"] as? String ?? ""
    }
}
