//
//  UserService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import Firebase

typealias FirestoreCompletion = (Error?) -> Void

struct UserService {
    
    ///uid → comp(user)  profileController、feedControllerから。エラーハンドリングは良いかと。-----------------------------------------------------------------------------------
    static func fetchUser(withUid uid: String, completion: @escaping (User) -> Void) {
        
        COLLECTION_USERS.document(uid).getDocument { snapshot, error in
            guard let dictionary = snapshot?.data() else { return }  //errorの時もここでreturnとなる。
            let user = User(dictionary: dictionary)
            completion(user)
        }
    }
    
    ///username: String → comp(user)    //同名の場合はどうなる？
    static func fetchUser(withUsername username: String, completion: @escaping(User?) -> Void) {
        
        COLLECTION_USERS.whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            guard let document = snapshot?.documents.first else {
                completion(nil)
                return
            }
            let user = User(dictionary: document.data())
            completion(user)
        }
    }
    
    ///指定されたコレクションの中に保存されている全てのuserのドキュメントID(UID)から[User]を作る
    private static func fetchUsers(fromCollection collection: CollectionReference, completion: @escaping([User]) -> Void) {
        
        var users = [User]()
        collection.getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            documents.forEach({ fetchUser(withUid: $0.documentID) { user in
                users.append(user)
                completion(users)
            } })
        }
    }
    
    //指定されたconfigEnumに従い条件分岐して[User]を返す。
    static func fetchUsers(forConfig config: UserFilterConfig, completion: @escaping([User]) -> Void) {
        
        switch config {
        case .followers(let uid):
            let ref = COLLECTION_FOLLOWERS.document(uid).collection("user-followers")
            fetchUsers(fromCollection: ref, completion: completion)
            
        case .following(let uid):
            let ref = COLLECTION_FOLLOWING.document(uid).collection("user-following")
            fetchUsers(fromCollection: ref, completion: completion)
            
        case .likes(let postId):
            let ref = COLLECTION_POSTS.document(postId).collection("post-likes")
            fetchUsers(fromCollection: ref, completion: completion)
            
        case .all, .messages:
            COLLECTION_USERS.getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else { return }
                
                let users = snapshot.documents.map({ User(dictionary: $0.data()) })
                completion(users)
            }
        }
    }
    //FeedControllerから。完全な分岐追跡とエラーハンドリングができている---------------------------------------------------------------------
    static func follow(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { completion(.failure(CustomError.currentUserNil)); return}
        let timestamp = Timestamp(date: Date())
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).setData(["timestamp": timestamp]) { error in
            if let error = error{ completion(.failure(error)); return }
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid)
                .setData(["timestamp": timestamp]) { (error) in
                    if let error = error{ completion(.failure(error)); return }
                    completion(.success("Succeed1"))
                }
        }
        COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid)
            .order(by: "timestamp", descending: true).limit(to: 3).getDocuments { (snapshot, error) in
                if let error = error{ completion(.failure(error)); return }
                guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
                documents.forEach {
                    let dictionary = ["ownerUid": uid, "postId": $0.documentID, "timestamp": Timestamp(date: Date())] as [String: Any]
                    COLLECTION_USERS.document(currentUid).collection("user-feed")
                        .document($0.documentID).setData(dictionary) { (error) in
                            if let error = error{ completion(.failure(error)); return }
                            completion(.success("Scceed2"))
                        }
                }
            }
    }
    
    //FeedControllerから。完全な分岐追跡とエラーハンドリングができている----------------------------------------------------------------------
    static func unfollow(uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { completion(.failure(CustomError.currentUserNil)); return}
        
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).delete { error in
            if let error = error{ completion(.failure(error)); return }
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid).delete { (error) in
                if let error = error{ completion(.failure(error)); return }
                completion(.success("Succeed1"))
            }
        }
        COLLECTION_USERS.document(currentUid).collection("user-feed")
            .whereField("ownerUid", isEqualTo: uid).getDocuments { (snapshot, error) in
                if let error = error{ completion(.failure(error)); return }
                guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
                documents.forEach({ $0.reference.delete { (error) in
                    if let error = error{ completion(.failure(error)); return }
                    completion(.success("Scceed2"))
                }})
                
            }
    }
    
//  uid → currentUIDがfollowしてるかどうか。profileControllerとFeedControllerから。エラーハンドリングの必要ないのでは?----------------
    static func checkIfUserIsFollowed(uid: String, completion: @escaping (Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).getDocument { (snapshot, error) in
            guard let isFollowed = snapshot?.exists else { return }
            completion(isFollowed)
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

