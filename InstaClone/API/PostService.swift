//
//  PostService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit
import Firebase

struct PostService {
    
    //[重要]投稿メソッド。Postモデルと見比べてみる事
    static func uploadPost(caption: String, image: UIImage, user: User, completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        //下の辞書の中に保存すべきpostID情報が入ってないがこれはローカルのみで扱う。hashTagはどうなってる?
        ImageUploader.uploadImage(image: image, imageKind: .feedImage) { (result) in
            switch result{
            case .failure(let error):
                return
            case .success(let imageUrl):
                let data = ["caption": caption,
                            "timestamp": Timestamp(date: Date()),
                            "likes": 0,
                            "imageUrl": imageUrl,
                            "ownerUid": uid,
                            "ownerImageUrl": user.profileImageUrl,
                            "ownerUsername": user.username] as [String : Any]
                            
                COLLECTION_POSTS.addDocument(data: data, completion: completion)
            
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
    
    //ProfileController下部のpost欄からPaginateion必要かと。-----------------------------------------------------------------------
    static func fetchPosts(forUser uid: String, completion: @escaping([Post]) -> Void) {
        let query = COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid)
        
        query.getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents else { return }
            
            var posts = documents.map({ Post(postId: $0.documentID, dictionary: $0.data()) })
            posts.sort(by: { $0.timestamp.seconds > $1.timestamp.seconds })
            
            completion(posts)
        }
    }
    
    static func fetchPost(withPostId postId: String, completion: @escaping(Post) -> Void) {
        COLLECTION_POSTS.document(postId).getDocument { snapshot, _ in
            guard let snapshot = snapshot else { return }
            guard let data = snapshot.data() else { return }
            let post = Post(postId: snapshot.documentID, dictionary: data)
            completion(post)
        }
    }
    
    static func fetchPosts(forHashtag hashtag: String, completion: @escaping([Post]) -> Void) {
        var posts = [Post]()
        COLLECTION_HASHTAGS.document(hashtag).collection("posts").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            documents.forEach({ fetchPost(withPostId: $0.documentID) { post in
                posts.append(post)
                completion(posts)
            } })
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
    
    static func checkIfUserLikedPost(post: Post, completion: @escaping(Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        //user-likesの中に個別のからのpostIDを作るのは一見コストがかかるように見えるがexistsを使う限り無料なのでむしろ効率的かと
        COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId).getDocument { (snapshot, _) in
            guard let didLike = snapshot?.exists else { return }
            completion(didLike)
        }
    }
    
    //12章で作ったメソッド。Cloud functionで裏で自動仕分け後、userのfeedコレクションから自分用feed postsを取り出す。
    static func fetchFeedPosts(completion: @escaping([Post]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var posts = [Post]()
        
        COLLECTION_USERS.document(uid).collection("user-feed").getDocuments { snapshot, error in
            
            snapshot?.documents.forEach({ document in
                fetchPost(withPostId: document.documentID) { post in
                    posts.append(post)
                    posts.sort(by: { $0.timestamp.seconds > $1.timestamp.seconds })
                    
                    completion(posts)
                }
            })
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
