//
//  Post.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Firebase

struct Post {
    
    let ownerUid: String
    let ownerImageUrl: String  //User情報からのduplicated info
    let ownerUsername: String  //User情報からのduplicated info
    let imageUrl: String
    var likes: Int  //runtime時にユーザーのアクション次第で値が変わるのでvar
    let caption: String  //なぜか不明だがvar。letで良いかと。
    let timestamp: Timestamp
    let hashtags: [String]
    let postId: String  //これはfetchをしてPostのイニシャライズ時に必要な引数として同時に代入される
    
    var didLike = false   //このプロパティはオブジェクト作成後に別のfetchから代入する。firestoreには保存しない。
    //このポストに対し自分がlikeしているかどうか
    
    
    init(postId: String, dictionary: [String: Any]) {
        
        self.ownerUid = dictionary["ownerUid"] as? String ?? ""
        self.ownerImageUrl = dictionary["ownerImageUrl"] as? String ?? ""
        self.ownerUsername = dictionary["ownerUsername"] as? String ?? ""
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.likes = dictionary["likes"] as? Int ?? 0
        self.caption = dictionary["caption"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.hashtags = dictionary["hashtags"] as? [String] ?? [String]()
        
        
        self.postId = postId    //init行を見て分かるとおり引数から代入される。
    }
}
