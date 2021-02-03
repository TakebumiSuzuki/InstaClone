//
//  Message.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Firebase

struct Message {  //設計に問題がある。具体的にはfromId用のusernameとprofileImageUrlが必要。チャットは相対的なものなので。
    
    let text: String
    let timestamp: Timestamp  //送信した瞬間の時間。他のデータと共に必ずセーブされるのでオプショナルでなくても良いと思うが。。
    let messageId: String
    let chatPartners: [String]
    
    let toId: String
    let toUsername: String  //toIDのusername
    let toProfileImageUrl: String  //toIDのprofileImageUrl
    
    let fromId: String
    let fromUsername: String
    let fromProfileImageUrl: String
    
    
    let isFromCurrentUser: Bool   //これは下のコンストラクタにある通りauthとfromIDを比べてその場で値を得て代入する
    var chatPartnerId: String { return isFromCurrentUser ? toId : fromId }
    var chatPartnerName: String { return isFromCurrentUser ? toUsername : fromUsername}
    var chatPartnerImageUrl: String { return isFromCurrentUser ? toProfileImageUrl : fromProfileImageUrl }
    
    
    //メッセージを送る時に、これとほぼ同じ辞書データがfirebase内の4箇所に同時に保存される。
    init(dictionary: [String: Any]) {
        self.text = dictionary["text"] as? String ?? ""
        self.timestamp = dictionary["timestamp"] as? Timestamp ?? Timestamp()
        self.messageId = dictionary["messageId"] as? String ?? ""
        self.chatPartners = dictionary["chatPartners"] as? [String] ?? [String]()
        
        self.toId = dictionary["toId"] as? String ?? ""
        self.toUsername = dictionary["toUsername"] as? String ?? ""
        self.toProfileImageUrl = dictionary["toProfileImageUrl"] as? String ?? ""
        
        self.fromId = dictionary["fromId"] as? String ?? ""
        self.fromUsername = dictionary["fromUsername"] as? String ?? ""
        self.fromProfileImageUrl = dictionary["fromProfileImageUrl"] as? String ?? ""
        
        self.isFromCurrentUser = fromId == Auth.auth().currentUser?.uid
        
        
    }
}
