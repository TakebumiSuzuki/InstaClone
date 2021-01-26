//
//  Message.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Firebase

struct Message {  //設計に問題がある。具体的にはfromId用のusernameとprofileImageUrlが必要。チャットは相対的なものなので。
    
    let text: String
    let toId: String
    let username: String  //toIDのusername
    let profileImageUrl: String  //toIDのprofileImageUrl
    let fromId: String
    var timestamp: Date?  //送信した瞬間の時間。他のデータと共に必ずセーブされるのでオプショナルでなくても良いと思うが。。
    
    let isFromCurrentUser: Bool   //これは下のコンストラクタにある通りauthとfromIDを比べてその場で値を得て代入する
    var chatPartnerId: String { return isFromCurrentUser ? toId : fromId }
    
    
    //メッセージを送る時に、これとほぼ同じ辞書データがfirebase内の4箇所に同時に保存される。
    init(dictionary: [String: Any]) {
        self.text = dictionary["text"] as? String ?? ""
        self.toId = dictionary["toId"] as? String ?? ""
        self.fromId = dictionary["fromId"] as? String ?? ""
        self.isFromCurrentUser = fromId == Auth.auth().currentUser?.uid
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? ""
        self.username = dictionary["username"] as? String ?? ""
        //以下自分のコード
        if let timestamp = dictionary["timestamp"] as? Timestamp{
            self.timestamp = timestamp.dateValue()
        }
        
//        if let timestamp = dictionary["timestamp"] as? Double {  //ここの行がダメ。nilになってい他ので自分で上で作った
//            self.timestamp = Date(timeIntervalSince1970: timestamp)
//        }
    }
}
