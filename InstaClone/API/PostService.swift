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
                            .setData(["timestamp": timestamp, "ownerUid": uid, "postId":docNewRef.documentID], completion: completion)
                    })
                    COLLECTION_USERS.document(uid).collection("user-feed").document(docNewRef.documentID)  //自分自身のフィードにも。
                        .setData(["timestamp": timestamp, "ownerUid": uid, "postId":docNewRef.documentID], completion: completion)
                }
            }
        }
    }
    
    //searchControllerより。全ポスト取得。-------------------------------------------------------------------------------
    static func fetchPosts(completion: @escaping ([Post]) -> Void) {
        COLLECTION_POSTS.order(by: "timestamp", descending: true).getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents else { return }
            
            let posts = documents.map({ Post(dictionary: $0.data()) })
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
            var posts = documents.map({ Post(dictionary: $0.data()) })
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
            guard let data = snapshot?.data() else {
                completion(.failure(CustomError.dataHandling))
                return
            }
            let post = Post(dictionary: data)
            completion(.success(post))
        }
    }
    
    //SearchControllerから。----------------------------------------------------------------
    static func fetchPosts(forHashtag hashtag: String, completion: @escaping ([Post]) -> Void) {
        var posts = [Post]()
        COLLECTION_POSTS.whereField("hashtags", arrayContains: hashtag).getDocuments { (snapshot, error) in
            if let error = error {
                print("DEBUG Error fetching hashtag posts \(error.localizedDescription)")
            }
            guard let documents = snapshot?.documents else{ return }
            posts = []
            documents.forEach { (document) in
                posts.append(Post(dictionary: document.data()))
            }
            completion(posts)
        }
    }
    
    //FeelControllerから。----------------------------------------------------------------------------
    static func likePost(post: Post, completion: @escaping(FirestoreCompletion)) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_POSTS.document(post.postId).updateData(["likes": post.likes])
        
        let timestamp = Timestamp(date: Date())
        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).setData(["timestamp": timestamp]) { _ in
        }
    }
    //FeelControllerから。----------------------------------------------------------------------------
    static func unlikePost(post: Post, completion: @escaping(FirestoreCompletion)) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard post.likes >= 0 else { return }
        
        COLLECTION_POSTS.document(post.postId).updateData(["likes": post.likes])
        
        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).delete { _ in
        }
    }
    
    //FeelControllerから。----------------------------------------------------------------------------
    static func checkIfUserLikedPost(post: Post, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).getDocument { (snapshot, error) in
            guard let didLike = snapshot?.exists else { return }
            completion(didLike)
        }
        
        
        //user-likesの中に個別のからのpostIDを作るのは一見コストがかかるように見えるがexistsを使う限り無料なのでむしろ効率的かと
//        COLLECTION_USERS.document(uid).collection("user-likes").document(post.postId).getDocument { (snapshot, _) in
//            guard let didLike = snapshot?.exists else { return }
//            completion(didLike)
//        }
    }
    
    //userのfeedコレクションから自分用feed postsを取り出す。---------------------------------------------
    static func fetchFeedPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { print("Authエラーです");return }
        var posts = [Post]()
        
        COLLECTION_USERS.document(uid).collection("user-feed").getDocuments { snapshot, error in
            if let error = error{
                completion(.failure(error))
                return
            }
            
            let group = DispatchGroup()
            snapshot?.documents.forEach({ document in  //ここでsnapshot = nilの時には下のnotifyに行って空のpostsとして処理される。
                group.enter()
                fetchPost(withPostId: document.documentID) { (result) in
                    switch result{
                    case .failure(let error):
                        print("DEBUG: Error fetching a single Post \(error)")
                        group.leave()
                    case .success(let post):
                        var postMutable = post    //以下でlikeしたかどうか調べる。
                        
                        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).getDocument { (snapshot, error) in
                            guard let didLike = snapshot?.exists else{
                                posts.append(postMutable)
                                group.leave()
                                return    //errorの時はここで打ち止めとなりデフォルト値のfalseのままになるのでエラーハンドリングする必要なし。
                            }
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
    
    //FeedControllerから--------------------------------------------------------------------------
    static func deletePost(_ postId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }  //一般的な話、completionの記述の後にもreturnは必要。
        
        //ポストそのものを消去
        COLLECTION_POSTS.document(postId).delete { (error) in
            if let error = error{
                completion(.failure(error))
                return
            }
            completion(.success("Postの消去に成功しました"))
            
            
            //自分のフィード内の自分のポストの消去
            COLLECTION_USERS.document(uid).collection("user-feed").document(postId).delete{ (error) in
                if let error = error{
                    completion(.failure(error))
                    return
                }
                completion(.success("自分のフィード内の自分のポストの消去に成功しました"))
                
                
                //フォロワーの人それぞれのuser-feed
                Firestore.firestore().collectionGroup("user-feed")
                    .whereField("postId", isEqualTo: postId).getDocuments { (snapshot, error) in
                        
                        if let error = error{
                            completion(.failure(error))
                            return
                        }
                        guard let documents = snapshot?.documents else {
                            completion(.failure(CustomError.snapShotIsNill))
                            return
                        }
                        let group = DispatchGroup()
                        for document in documents{
                            group.enter()
                            document.reference.delete { (error) in
                                if let error = error{
                                    completion(.failure(error))
                                    group.leave()
                                    return
                                }
                                group.leave()
                            }
                        }
                        group.notify(queue: .main) {
                            completion(.success("YES1"))
                        }
                }
            }
        }
        
        //Postコレクションの中のサブコレクション(post-likesコレクション)の消去
        COLLECTION_POSTS.document(postId).collection("post-likes").getDocuments { (snapshot, error) in
            if let error = error{
                completion(.failure(error))
                return
            }
            guard let documents = snapshot?.documents else {
                completion(.failure(CustomError.snapShotIsNill))
                return
            }
            documents.forEach { $0.reference.delete { (error) in
                if let error = error {
                    completion(.failure(error))
                }
                return
            }}
            completion(.success("YES2"))
        }
        //後は下にある、notificationと、コメントも。できたら。。
//        let notificationQuery = COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications")
//        notificationQuery.whereField("postId", isEqualTo: postId).getDocuments { snapshot, _ in
//            guard let documents = snapshot?.documents else { return }
//            documents.forEach({ $0.reference.delete(completion: completion) })
//        }  //ここは不明
    }
}
