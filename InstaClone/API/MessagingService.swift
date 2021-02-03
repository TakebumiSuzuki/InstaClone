//
//  MessagingService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import Firebase

class MessagingService {
    
    var latestMessageListener: ListenerRegistration!
    var chatListener: ListenerRegistration!
    
    func fetchRecentMessages(completion: @escaping ([Message]) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        var messages = [Message]()
        let query = COLLECTION_MESSAGES.whereField("chatPartners", arrayContains: currentUid).order(by: "timestamp", descending: true)
        
        latestMessageListener = query.addSnapshotListener { (snapshot, error) in
            guard let documents = snapshot?.documents else{return}
            
            messages = documents.map { Message(dictionary: $0.data()) }
            completion(messages)
        }
    }
    
    //documentChangesの.addedを使いその後appendしているがその必要はない。firebaseのsnapshotは普通に自動で最小のDL量で完成形を出してくれるので。
    func fetchMessages(forUser user: User, completion: @escaping ([Message]) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let documentID = user.uid > currentUid ? "\(user.uid)_\(currentUid)" : "\(currentUid)_\(user.uid)"
        
        var messages = [Message]()
        let query = COLLECTION_MESSAGES.document(documentID).collection("messages").order(by: "timestamp")
        
        chatListener = query.addSnapshotListener { (snapshot, error) in
            guard let documents = snapshot?.documents else{return}
            
            messages = documents.map { Message(dictionary: $0.data()) }
            completion(messages)
        }
    }
    
    
    //重要。data辞書を自分と相手のmessage用のスペースに保存し、さらにそれぞれのrecent-messagesスペースに.setDataで消去保存する。
    static func uploadMessage(_ message: String, to user: User, completion: @escaping(Error?) -> Void) {
        
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        UserService.fetchUser(withUid: currentUid) { (currentUser) in
            
            let documentID = user.uid > currentUser.uid ? "\(user.uid)_\(currentUser.uid)" : "\(currentUser.uid)_\(user.uid)"
            let chatPartners: [String] = user.uid > currentUser.uid ? [user.uid, currentUser.uid] : [currentUser.uid, user.uid]
            
            let docRef = COLLECTION_MESSAGES.document(documentID).collection("messages").document()
            
            let messageData = ["text": message,
                               "timestamp": Timestamp(date: Date()),
                               "messageId": docRef.documentID,
                               "chatPartners": chatPartners,
                               
                               "toId": user.uid,
                               "toUsername": user.username,  //相手の名前
                               "toProfileImageUrl": user.profileImageUrl,  //相手のImageUrl
                               
                               "fromId": currentUid,
                               "fromUsername": currentUser.username,
                               "fromProfileImageUrl": currentUser.profileImageUrl] as [String : Any]
            
            docRef.setData(messageData) { (error) in
                if let error = error{
                    completion(error)
                }
                completion(nil)
            }
            
            COLLECTION_MESSAGES.document(documentID).setData(messageData) { (error) in
                if let error = error{
                    completion(error)
                }
                completion(nil)
            }
        }
    }
}
