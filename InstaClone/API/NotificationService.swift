//
//  NotificationService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Firebase

struct NotificationService {
    
    //ProfileHeader(follow), NotificationController(follow), commentController(comment), FeedController(like)multi post,
    //FeedController(like)single post の以上５箇所から呼ばれる。-------------------------------------------------------------
    static func uploadNotification(toUid uid: String, fromUser: User, type: NotificationType, post: Post? = nil,
                                   completion: @escaping FirestoreCompletion) {
        guard let currentUid = Auth.auth().currentUser?.uid else { completion(CustomError.currentUserNil); return }
        guard uid != currentUid else { return }  //自分自身にはnotificationを送らないように。これのエラーハンドリングする必要はないかと。
        
        //ここで以下のようなステップを踏む事でdocRef.documentIDというドキュメント自身のパス名文字列をアップロードできるようになる。
        let docRef = COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications").document()
        
        var data: [String: Any] = ["timestamp": Timestamp(date: Date()),
                                   "uid": fromUser.uid,  //発信元のuid
                                   "type": type.rawValue,
                                   "id": docRef.documentID,
                                   "userProfileImageUrl": fromUser.profileImageUrl,  //発信元のprofileImageUrl
                                   "username": fromUser.username]  //発信元のusername
        
        if let post = post {   //ポストがある場合にはその情報も
            data["postId"] = post.postId
            data["postImageUrl"] = post.imageUrl
        }
        
        docRef.setData(data, completion: completion)
    }
    
    
    
    //profileController、NotificationControllerから(unfollowした時)。--------------------------------------------------------
    //またFeedControlleeから(unlikeした時)。
    //かなりトリッキーな方法で、相手のnotificationの中で自分から送られたものを全て取り出しnotificationオブジェクトに変換する。
    //それをforEachでしらみ潰しにフィルターをかけながら目的のnotificationオブジェクトを特定し、そのreferenceを使ってdelete()
    static func deleteNotification(toUid uid: String, type: NotificationType, postId: String? = nil) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        //実はuploadNotificationした時に保存してあるdocRef情報で一発特定削除できると思われる事に気づいた。。
        COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications")
            .whereField("uid", isEqualTo: currentUid).getDocuments { snapshot, _ in
                snapshot?.documents.forEach({ document in
                    let notification = Notification(dictionary: document.data())
                    guard notification.type == type else { return }      //typeが同じものだけをフィルター。
                    
                    if postId != nil {           //notificationの種類がlikeかcommentの時はpostIDが同じものだけをフィルター。
                        guard postId == notification.postId else { return }
                    }
                    
                    document.reference.delete()
                })
            }
    }
    
    
    //notificationControllerから--------------------------------------------------------------------------------------------
    static func fetchNotifications(completion: @escaping (Result<[Notification], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion(.failure(CustomError.currentUserNil)); return }
        
        let query =  COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications")
            .order(by: "timestamp", descending: true).limit(to: 30)
       
        query.getDocuments { snapshot, error in
            if let error = error { completion(.failure(error)); return }
            guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
            
            let notifications = documents.map({ Notification(dictionary: $0.data()) })
            completion(.success(notifications))
        }
    }
}
