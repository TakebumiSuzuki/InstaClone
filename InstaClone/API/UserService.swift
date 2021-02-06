//
//  UserService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import Firebase

typealias FirestoreCompletion = (Error?) -> Void

struct UserService {
    
    //profileController、feedController、notificationControllerから。-------------------------------------------------
    static func fetchUser(withUid uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        
        COLLECTION_USERS.document(uid).getDocument { snapshot, error in
            if let error = error{ completion(.failure(error)); return }
            guard let dictionary = snapshot?.data() else { completion(.failure(CustomError.snapShotIsNill)); return }
            
            let user = User(dictionary: dictionary)
            completion(.success(user))
        }
    }
    
    //username: String → comp(user) FeedControllerから。---------------------------------------------------------------
    static func fetchUser(withUsername username: String, completion: @escaping (User?) -> Void) {
        
        COLLECTION_USERS.whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            guard let document = snapshot?.documents.first else {  //errorの場合も、ここで一緒にreturnされる。
                completion(nil)
                return
            }
            let user = User(dictionary: document.data())
            completion(user)
        }
    }
    
    ///指定されたコレクションの中に保存されている全てのuserのドキュメントID(UID)から[User]を作る
    private static func fetchUsers(fromCollection collection: CollectionReference, completion: @escaping(Result<[User], Error>) -> Void) {
        
        var users = [User]()
        collection.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
            let group = DispatchGroup()
            
            documents.forEach({
                group.enter()
                fetchUser(withUid: $0.documentID) { (result) in
                    switch result{
                    case .failure(let error):
                        completion(.failure(error))
                        group.leave()
                    case .success(let user):
                        users.append(user)
                        group.leave()
                    }
            } })
            group.notify(queue: .main) {
                completion(.success(users))
            }
        }
    }
    
    
    //指定されたconfigEnumに従い条件分岐して[User]を返す----------------------------------------------------------------
    static func fetchUsers(forConfig config: UserFilterConfig, completion: @escaping (Result<[User], Error>) -> Void) {
        var ref: CollectionReference?
        switch config {
        case .all:  //全ユーザー取得。
            ref = nil
            COLLECTION_USERS.getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else { completion(.failure(CustomError.snapShotIsNill)); return }
                
                let users = snapshot.documents.map({ User(dictionary: $0.data()) })
                completion(.success(users))
                return
            }
        case .followers(let uid):
            ref = COLLECTION_FOLLOWERS.document(uid).collection("user-followers")
            
        case .following(let uid):
            ref = COLLECTION_FOLLOWING.document(uid).collection("user-following")
            
        case .likes(let postId):
            ref = COLLECTION_POSTS.document(postId).collection("post-likes")
        
        case .messages(let uid):
            ref = COLLECTION_FOLLOWING.document(uid).collection("user-following")
        }
        
        guard let reference = ref else { return }
        fetchUsers(fromCollection: reference) { (result) in
            switch result{
            case .failure(let error):
                completion(.failure(error))
            case .success(let users):
                completion(.success(users))
            }
        }
    }
    //FeedController、NotificationControllerから。完全な分岐追跡とエラーハンドリングができている----------------------------------------------
    static func follow(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { completion(.failure(CustomError.currentUserNil)); return}
        
        //それぞれのuserコレクションの中にあるfollowing/followersコレクションにお互いのuidを書き合う。
        let timestamp = Timestamp(date: Date())
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).setData(["timestamp": timestamp]) { error in
            if let error = error{ completion(.failure(error)); return }
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid)
                .setData(["timestamp": timestamp]) { (error) in
                    if let error = error{ completion(.failure(error)); return }
                    completion(.success("Succeed"))
                }
        }
        
        //フォローした人の最近3つの投稿のpostIDをとってきて、それを自分のuser-feedの中に現在の時刻で記録する。
        COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid)
            .order(by: "timestamp", descending: true).limit(to: 3).getDocuments { (snapshot, error) in
                if let error = error{ completion(.failure(error)); return }
                guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
                documents.forEach {
                    let dictionary = ["ownerUid": uid, "postId": $0.documentID, "timestamp": timestamp] as [String: Any]
                    COLLECTION_USERS.document(currentUid).collection("user-feed")
                        .document($0.documentID).setData(dictionary) { (error) in
                            if let error = error{ completion(.failure(error)); return }
                            //ここでcompletion(.success())は必要ない。なぜなら既に一度１０行上のブロックで呼んでいるから。
                            // ここにもう一度completionを書くと、複数回escapintCompHandlerが起動することになってしまう。
                        }
                }
            }
    }
    
    //FeedController、NotificationControllerから。完全な分岐追跡とエラーハンドリングができている----------------------------------------------
    static func unfollow(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { completion(.failure(CustomError.currentUserNil)); return}
        
        //それぞれのuserコレクションの中にあるfollowing/followersコレクションの中のお互いのuidを削除する。
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).delete { error in
            if let error = error{ completion(.failure(error)); return }
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid).delete { (error) in
                if let error = error{ completion(.failure(error)); return }
                completion(.success("Succeed"))
            }
        }
        
        //自分のuser-feedの中からフォローしていた人の投稿を全て消す。
        COLLECTION_USERS.document(currentUid).collection("user-feed")
            .whereField("ownerUid", isEqualTo: uid).getDocuments { (snapshot, error) in
                if let error = error{ completion(.failure(error)); return }
                guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
                documents.forEach({ $0.reference.delete { (error) in
                    if let error = error{ completion(.failure(error)); return }
                    //ここでcompletion(.success())は必要ない。なぜなら既に一度上の方で呼んでいるから。
                    // ここにもう一度completionを書くと、複数回escapingCompHandlerが起動することになってしまう。
                }})
                
            }
    }
    
    
//  uid → currentUIDがfollowしてるかどうか。profileControllerとFeedControllerから。エラーハンドリングの必要ないのでは?----------------
    static func checkIfUserIsFollowed(uid: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { completion(.failure(CustomError.currentUserNil));return }
        
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).getDocument { (snapshot, error) in
            if let error = error{ completion(.failure(error)); return}
            guard let isFollowed = snapshot?.exists else { completion(.failure(CustomError.snapShotIsNill)); return }
            completion(.success(isFollowed))
        }
    }
    //--------------------------------------------------------------------------------------
    static func fetchUserStats(uid: String, completion: @escaping (UserStats) -> Void) {
        
        var followers = 0
        var following = 0
        var posts = 0
        
        let group = DispatchGroup()
        //各APIアクセスのerrorをハンドルする必要はない。errorになってもUI上では初期値０のままで表示し続ければ良いので。
        group.enter()
        COLLECTION_FOLLOWERS.document(uid).collection("user-followers").getDocuments { (snapshot, _) in
            followers = snapshot?.documents.count ?? 0
            group.leave()
        }
        
        group.enter()
        COLLECTION_FOLLOWING.document(uid).collection("user-following").getDocuments { (snapshot, _) in
            following = snapshot?.documents.count ?? 0
            group.leave()
        }
        
        group.enter()
        COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid).getDocuments { (snapshot, _) in
            posts = snapshot?.documents.count ?? 0
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(UserStats(followers: followers, following: following, posts: posts))
        }
        
    }
    
    //--------------------------------------------------------------------------------------
    static func updateProfileImage(forUser user: User, image: UIImage, completion: @escaping (String?, Error?) -> Void) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Storage.storage().reference(forURL: user.profileImageUrl).delete(completion: nil)
        
        ImageUploader.uploadImage(image: image, imageKind: .profileImage) { (result) in
            
            switch result{
            case .failure(let error):
                completion(nil, error)
                
            case .success(let profileImageUrl):
                completion(profileImageUrl, nil)
                
//                let data = ["profileImageUrl": profileImageUrl]
                //過去のポストに含まれるprofilrImageUrlをfor loopを使って全て更新。
//                    COLLECTION_POSTS.whereField("ownerUid", isEqualTo: user.uid).getDocuments { snapshot, error in
//                        guard let documents = snapshot?.documents else { return }
//                        let data = ["ownerImageUrl": profileImageUrl]
//                        documents.forEach({ COLLECTION_POSTS.document($0.documentID).updateData(data) })
//                    }
                    // need to update profile image url in comments and messages
            }
        }
    }
    
    ///userオブジェクトをsetで保存。パスはuid-------------------------------------------------------------------------------------------
    static func saveUserData(user: User, completion: @escaping (FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = ["email": user.email,  //将来的にemailも変更できるようにした場合にはこのラインが必要となる
                                   "fullname": user.fullname,
                                   "profileImageUrl": user.profileImageUrl,
                                   "username": user.username]
        
        COLLECTION_USERS.document(uid).setData(data, merge: true, completion: completion)
    }
    
    
    static func setUserFCMToken() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let fcmToken = Messaging.messaging().fcmToken else { return }

        COLLECTION_USERS.document(uid).updateData(["fcmToken": fcmToken])
    }
}

