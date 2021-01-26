//
//  UserService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import Firebase

typealias FirestoreCompletion = (Error?) -> Void

struct UserService {
    
    ///uid → comp(user)
    static func fetchUser(withUid uid: String, completion: @escaping(User) -> Void) {
        
        COLLECTION_USERS.document(uid).getDocument { snapshot, error in
            guard let dictionary = snapshot?.data() else { return }
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
        
    static func follow(uid: String, completion: @escaping(FirestoreCompletion)) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).setData([:]) { error in
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid).setData([:], completion: completion)
        }
    }
    
    static func unfollow(uid: String, completion: @escaping(FirestoreCompletion)) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following")
            .document(uid).delete { error in
                COLLECTION_FOLLOWERS.document(uid).collection("user-followers").document(currentUid).delete(completion: completion)
        }
    }
    
    ///プロフィールページのuid → currentUIDがfollowしてるかどうかのBool
    static func checkIfUserIsFollowed(uid: String, completion: @escaping(Bool) -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_FOLLOWING.document(currentUid).collection("user-following").document(uid).getDocument { (snapshot, error) in
            guard let isFollowed = snapshot?.exists else { return }
            completion(isFollowed)
        }
    }
    
    static func fetchUserStats(uid: String, completion: @escaping(UserStats) -> Void) {
        COLLECTION_FOLLOWERS.document(uid).collection("user-followers").getDocuments { (snapshot, _) in
            let followers = snapshot?.documents.count ?? 0
            
            COLLECTION_FOLLOWING.document(uid).collection("user-following").getDocuments { (snapshot, _) in
                let following = snapshot?.documents.count ?? 0
                
                COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid).getDocuments { (snapshot, _) in
                    let posts = snapshot?.documents.count ?? 0
                    
                    completion(UserStats(followers: followers, following: following, posts: posts))
                }
            }
        }
    }
    
    static func updateProfileImage(forUser user: User, image: UIImage, completion: @escaping(String?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Storage.storage().reference(forURL: user.profileImageUrl).delete(completion: nil)
                
        ImageUploader.uploadImage(image: image) { profileImageUrl in
            let data = ["profileImageUrl": profileImageUrl]
            
            COLLECTION_USERS.document(uid).updateData(data) { error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                //過去のポストに含まれるprofilrImageUrlをfor loopを使って全て更新。
                COLLECTION_POSTS.whereField("ownerUid", isEqualTo: user.uid).getDocuments { snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    let data = ["ownerImageUrl": profileImageUrl]
                    documents.forEach({ COLLECTION_POSTS.document($0.documentID).updateData(data) })
                }
                
                // need to update profile image url in comments and messages
                
                completion(profileImageUrl, nil)
            }
        }
    }
    
    ///userオブジェクトをsetで保存。パスはuid
    static func saveUserData(user: User, completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = ["email": user.email,
                                   "fullname": user.fullname,
                                   "profileImageUrl": user.profileImageUrl,
                                   "uid": uid,
                                   "username": user.username]
        
        COLLECTION_USERS.document(uid).setData(data, completion: completion)
    }
    
    static func setUserFCMToken() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let fcmToken = Messaging.messaging().fcmToken else { return }

        COLLECTION_USERS.document(uid).updateData(["fcmToken": fcmToken])
    }
}

