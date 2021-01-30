//
//  PostService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit
import Firebase

struct PostService {
    
    //[重要]投稿メソッド。Postモデルと見比べてみる事-------------------------------------------
    static func uploadPost(caption: String, image: UIImage, hashtags: [String], user: User, completion: @escaping (FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }  //Userがあるから必要ないのでは？
        
        ImageUploader.uploadImage(image: image, imageKind: .feedImage) { (result) in  //投稿画像アップロード
            switch result{
            case .failure(let error):
                completion(error)
            case .success(let imageUrl):
                let docNewRef = COLLECTION_POSTS.document()
                let timestamp = Timestamp(date: Date())
                let data = ["caption": caption,
                            "timestamp": timestamp,
                            "likes": 0,
                            "imageUrl": imageUrl,
                            "ownerUid": uid,
                            "ownerImageUrl": user.profileImageUrl,
                            "ownerUsername": user.username,
                            "hashtags": hashtags,
                            "postId": docNewRef.documentID] as [String : Any]
                docNewRef.setData(data, completion: completion)           //PostオブジェクトをPostコレクションにセーブ
                
                COLLECTION_FOLLOWERS.document(uid).collection("user-followers").getDocuments {(snapshot, error) in//フォロワーget
                    if let error = error{
                        print("Error fetching followers snapshot. \(error.localizedDescription)")
                        completion(error)
                    }
                    snapshot?.documents.forEach({ (document) in
                        
                        let followerUid = document.documentID         //フォロワーのuser-feedにドキュメント格納。
                        COLLECTION_USERS.document(followerUid).collection("user-feed").document(docNewRef.documentID)
                            .setData(["timestamp": timestamp, "postID": docNewRef.documentID], completion: completion)
                    })
                    COLLECTION_USERS.document(uid).collection("user-feed").document(docNewRef.documentID)
                        .setData(["timestamp": timestamp, "postID": docNewRef.documentID], completion: completion)
                }
            }
        }
    }
    
    
    static func fetchPosts(completion: @escaping([Post]) -> Void) {
        COLLECTION_POSTS.order(by: "timestamp", descending: true).getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents else { return }
            
            let posts = documents.map({ Post(postId: $0.documentID, dictionary: $0.data()) })
            completion(posts)
        }
    }
    
    //特定のuidのポストを時系列に。ProfileController下部のpost欄から。Paginateion必要かと。--------------------------------------------
    static func fetchPosts(forUser uid: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        let query = COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid)
        
        query.getDocuments { (snapshot, error) in
            if let error = error{
                completion(.failure(error))
            }
            guard let documents = snapshot?.documents else { return }
            var posts = documents.map({ Post(postId: $0.documentID, dictionary: $0.data()) })
            posts.sort(by: { $0.timestamp.seconds > $1.timestamp.seconds })
            completion(.success(posts))
        }
    }
    
    //FeedControllerから。単体PostIDからPost作成-------------------------------------------------------------
    static func fetchPost(withPostId postId: String, completion: @escaping (Result<(Post), Error>) -> Void) {
        
        COLLECTION_POSTS.document(postId).getDocument { snapshot, error in
            if let error = error{
                completion(.failure(error))
            }
            guard let snapshot = snapshot else { return }
            guard let data = snapshot.data() else { return }
            let post = Post(postId: snapshot.documentID, dictionary: data)
            completion(.success(post))
        }
    }
    
    //最後にDEBUG
    static func fetchPosts(forHashtag hashtag: String, completion: @escaping([Post]) -> Void) {
        var posts = [Post]()
        COLLECTION_HASHTAGS.document(hashtag).collection("posts").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            
//            documents.forEach({ fetchPost(withPostId: $0.documentID) { post in
//                posts.append(post)
//                completion(posts)
//            } })
        }
    }
    
    static func likePost(post: Post, completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_POSTS.document(post.postId).updateData(["likes": post.likes + 1])
        
        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).setData([:]) { _ in
            COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId).setData([:], completion: completion)
        }
    }
    
    static func unlikePost(post: Post, completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard post.likes > 0 else { return }
        
        COLLECTION_POSTS.document(post.postId).updateData(["likes": post.likes - 1])
        
        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).delete { _ in
            COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId).delete(completion: completion)
        }
    }
    
    //-----------------------------------------------------------------------------------------
    static func checkIfUserLikedPost(post: Post, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        //user-likesの中に個別のからのpostIDを作るのは一見コストがかかるように見えるがexistsを使う限り無料なのでむしろ効率的かと
        COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId).getDocument { (snapshot, _) in
            guard let didLike = snapshot?.exists else { return }
            completion(didLike)
        }
    }
    
    //userのfeedコレクションから自分用feed postsを取り出す。---------------------------------------------
    static func fetchFeedPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var posts = [Post]()
        
        COLLECTION_USERS.document(uid).collection("user-feed").getDocuments { snapshot, error in
            if let error = error{ completion(.failure(error)) }
            let group = DispatchGroup()
            
            snapshot?.documents.forEach({ document in
                group.enter()
                fetchPost(withPostId: document.documentID) { (result) in
                    switch result{
                    case .failure(let error):
                        print("DEBUG: Error fetching a single Post \(error)")
                        group.leave()
                    case .success(let post):
                        var postMutable = post
                        COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId).getDocument { (snapshot, _) in
                            guard let didLike = snapshot?.exists else { return }
                            postMutable.didLike = didLike
                            posts.append(postMutable)
                            group.leave()
                        }
                    }
                }
            })
            group.notify(queue: .main) {
                posts.sort(by: { $0.timestamp.seconds > $1.timestamp.seconds })
                completion(.success(posts))
            }
        }
    }
    
    static func deletePost(_ postId: String, completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_POSTS.document(postId).collection("post-likes").getDocuments { snapshot, _ in
            guard let uids = snapshot?.documents.map({ $0.documentID }) else { return }
            uids.forEach({ COLLECTION_USERS.document($0).collection("user-likes").document(postId).delete() })
        }  //上は各userの中のサブコレクションのuser-likesの中から該当するpostIDを消去している。そもそもuser-likesの記録はいらないのでは？
        
        
        COLLECTION_POSTS.document(postId).delete { _ in   //ポストそのものを消去しているが、サブコレクションは消去されてない
            COLLECTION_FOLLOWERS.document(uid).collection("user-followers").getDocuments { snapshot, _ in
                guard let uids = snapshot?.documents.map({ $0.documentID }) else { return }
                uids.forEach({ COLLECTION_USERS.document($0).collection("user-feed").document(postId).delete() })
                  //フォロワーのそれぞれのuser-feedから該当のpostIDを消している。この作業はuser-feedコレクションクエリでもっと簡単にできるはず。
                
                
                let notificationQuery = COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications")
                notificationQuery.whereField("postId", isEqualTo: postId).getDocuments { snapshot, _ in
                    guard let documents = snapshot?.documents else { return }
                    documents.forEach({ $0.reference.delete(completion: completion) })
                }  //ここは不明
            }
        }
    }
}
