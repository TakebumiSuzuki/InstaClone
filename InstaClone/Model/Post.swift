//
//  Post.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Firebase

struct Post {
    
    let postId: String
    let ownerUid: String
    let ownerImageUrl: String  //User情報からのduplicated info
    let ownerUsername: String  //User情報からのduplicated info
    let imageUrl: String
    var likes: Int  //runtime時にユーザーのアクション次第で値が変わるのでvar
    let caption: String
    let timestamp: Timestamp
    let hashtags: [String]
    
    
    var didLike = false   //このプロパティはオブジェクト作成後に別のAPIfetchから代入する。firestoreには保存しない。
    //このポストに対し自分がlikeしているかどうか
    
    
    init(dictionary: [String: Any]) {
        
        self.postId = dictionary["postId"] as? String ?? ""
        self.ownerUid = dictionary["ownerUid"] as? String ?? ""
        self.ownerImageUrl = dictionary["ownerImageUrl"] as? String ?? ""
        self.ownerUsername = dictionary["ownerUsername"] as? String ?? ""
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.likes = dictionary["likes"] as? Int ?? 0
        self.caption = dictionary["caption"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.hashtags = dictionary["hashtags"] as? [String] ?? [String]()
        
    }
}
