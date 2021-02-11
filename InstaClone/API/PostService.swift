//
//  PostService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit
import Firebase

class PostService {
    
    //UploadPostControllerから。--------------------------------------------------------------------------------------
    static func uploadPost(caption: String, image: UIImage, hashtags: [String], user: User, completion: @escaping (FirestoreCompletion)) {
        
        ImageUploader.uploadImage(image: image, imageKind: .feedImage) { (result) in  //投稿画像アップロード
            switch result{
            case .failure(let error):
                completion(error)
            case .success(let imageUrl):
                let docRef = COLLECTION_POSTS.document()  //ここでパスを作って、documentIDをdataに記入できるようにしている。
                let timestamp = Timestamp(date: Date())
                let data = ["caption": caption,
                            "timestamp": timestamp,
                            "likes": 0,
                            "imageUrl": imageUrl,
                            "ownerUid": user.uid,
                            "ownerImageUrl": user.profileImageUrl,
                            "ownerUsername": user.username,
                            "hashtags": hashtags,
                            "postId": docRef.documentID] as [String : Any]
                docRef.setData(data) { (error) in
                    if let error = error { completion(error); return }  //Postコレクションにdictionaryをセーブ
                }
                
                //以下がフォロワーのfeedに書き込む作業。
                COLLECTION_FOLLOWERS.document(user.uid).collection("user-followers").getDocuments {(snapshot, error) in//フォロワーget
                    if let error = error{ completion(error); return }
                    guard let snapshot = snapshot else { completion(CustomError.snapShotIsNill); return }
                    
                    let userFeedData = ["timestamp": timestamp, "ownerUid": user.uid, "postId":docRef.documentID] as [String : Any]
                    
                    let group = DispatchGroup()
                    
                    snapshot.documents.forEach({ (document) in
                        group.enter()
                        let followerUid = document.documentID         //フォロワーのuser-feedにドキュメント格納。
                        COLLECTION_USERS.document(followerUid).collection("user-feed").document(docRef.documentID)
                            .setData(userFeedData) { (error) in
                                if let error = error { completion(error); group.leave(); return}
                                group.leave()
                            }
                    })
                    group.enter()  //投稿者の自分自身のフィードにも。
                    COLLECTION_USERS.document(user.uid).collection("user-feed").document(docRef.documentID)
                        .setData(userFeedData) { (error) in
                            if let error = error { completion(error); group.leave(); return}
                            group.leave()
                        }
                    
                    group.notify(queue: .main) {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    //searchControllerから。全ポスト取得。--------------------------------------------------------------------------------------
    static func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        COLLECTION_POSTS.order(by: "timestamp", descending: true).getDocuments { (snapshot, error) in
            if let error = error{ completion(.failure(error)); return }
            guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
            
            let posts = documents.map({ Post(dictionary: $0.data()) })
            completion(.success(posts))
        }
    }
    
    //ProfileController下部のpost欄から。特定のuidのポストを時系列に。Paginateion必要かと。-------------------------------------------
    static func fetchPosts(forUser uid: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        let query = COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid)
        
        query.getDocuments { (snapshot, error) in
            if let error = error{ completion(.failure(error)); return }
            guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
            
            var posts = documents.map({ Post(dictionary: $0.data()) })
            posts.sort(by: { $0.timestamp.seconds > $1.timestamp.seconds })
            completion(.success(posts))
        }
    }
    
    //FeedController、NotificationControllerから。単体PostIDからPost作成----------------------------------------------------------
    static func fetchPost(withPostId postId: String, completion: @escaping (Result<(Post), Error>) -> Void) {
        
        COLLECTION_POSTS.document(postId).getDocument { snapshot, error in
            if let error = error{ completion(.failure(error)); return }
            guard let data = snapshot?.data() else { completion(.failure(CustomError.dataHandling)); return }
            
            let post = Post(dictionary: data)
            completion(.success(post))
        }
    }
    
    //SearchController,HashtagPostControllerから。----------------------------------------------------------------------
    static func fetchPosts(forHashtag hashtag: String, completion: @escaping ([Post]) -> Void) {
        var posts = [Post]()
        COLLECTION_POSTS.whereField("hashtags", arrayContains: hashtag).getDocuments { (snapshot, error) in
            if let error = error {
                print("DEBUG: Error fetching hashtag posts: \(error.localizedDescription)")
            }
            guard let documents = snapshot?.documents else{ return }
            posts = []
            documents.forEach { (document) in
                posts.append(Post(dictionary: document.data()))
            }
            completion(posts)
        }
    }
    
    //FeedControllerから。-----------------------------------------------------------------------------------------------
    static func likePost(post: Post, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion(CustomError.currentUserNil); return }
        let group = DispatchGroup()
        
        group.enter()
        COLLECTION_POSTS.document(post.postId).updateData(["likes": FieldValue.increment(Int64(+1))]) { (error) in
            if let error = error{ completion(error); return}
            group.leave()
        }
        group.enter()
        let timestamp = Timestamp(date: Date())
        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).setData(["timestamp": timestamp]) { (error) in
            if let error = error{ completion(error); return}
            group.leave()
        }
        
        group.notify(queue: .main) { completion(nil) }
    }
    
    //FeelControllerから。-------------------------------------------------------------------------------------------------
    static func unlikePost(post: Post, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion(CustomError.currentUserNil); return }
        guard post.likes >= 0 else { completion(CustomError.postLikeIsMinus); return }
        let group = DispatchGroup()
        
        group.enter()
        COLLECTION_POSTS.document(post.postId).updateData(["likes": FieldValue.increment(Int64(-1))]) { (error) in
            if let error = error{ completion(error); return}
            group.leave()
        }
        group.enter()
        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).delete { (error) in
            if let error = error{ completion(error); return}
            group.leave()
        }
        
        group.notify(queue: .main) { completion(nil) }
    }
    
    //FeelControllerから。--------------------------------------------------------------------------------------------------
    static func checkIfUserLikedPost(post: Post, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion(.failure(CustomError.currentUserNil)); return }
        
        COLLECTION_POSTS.document(post.postId).collection("post-likes").document(uid).getDocument { (snapshot, error) in
            if let error = error { completion(.failure(error)); return}
            guard let didLike = snapshot?.exists else { completion(.failure(CustomError.snapShotIsNill)); return }
            
            completion(.success(didLike))
        }
    }
    
    
    static var lastPostDoc : DocumentSnapshot?
    //userのfeedコレクションから自分用feed postsを取り出す。----------------------------------------------------------------------
    static func fetchFeedPosts(isFirstFetch: Bool, completion: @escaping (Result<[Post], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {completion(.failure(CustomError.currentUserNil));return }
        var posts = [Post]()
        
        var ref: Query
        if isFirstFetch == true{
            ref = COLLECTION_USERS.document(uid).collection("user-feed").order(by: "timestamp", descending: true).limit(to: 3)
        }else{
            //ここをはしょってref.star()という風に書くと機能しない。
            guard let lastDocument = PostService.lastPostDoc else{return}
            ref = COLLECTION_USERS.document(uid).collection("user-feed").order(by: "timestamp", descending: true).limit(to: 3).start(afterDocument: lastDocument)
        }
        
        ref.getDocuments { snapshot, error in
            if let error = error{ completion(.failure(error)); return }
            guard let snapshot = snapshot else { completion(.failure(CustomError.snapShotIsNill)); return }
            
            print("PaginationでDLしたスナップショットの数は\(snapshot.documents.count)です。")
            PostService.lastPostDoc = snapshot.documents.last
            
            let group = DispatchGroup()
            snapshot.documents.forEach({ document in
                group.enter()
                PostService.fetchPost(withPostId: document.documentID) { (result) in
                    switch result{
                    case .failure(let error):
                        print("DEBUG: Error fetching each single Post from posts: \(error)")
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
                            group.leave()  //以上のforEach作業で時間順が崩れるので下で再度整列させている。
                        }
                    }
                }
            })
            group.notify(queue: .main) {
                posts.sort(by: { $0.timestamp.seconds > $1.timestamp.seconds })//もう一度ここで時間整列
                completion(.success(posts))
            }
        }
    }
    
    //FeedControllerから-------------------------------------------------------------------------------------------------
    static func deletePost(_ postId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { completion(.failure(CustomError.currentUserNil)); return }
        
        //ポストそのものを消去
        COLLECTION_POSTS.document(postId).delete { (error) in
            if let error = error{ completion(.failure(error)); return }
            
            print("Post自体の消去に成功しました")
            
            
            //自分のフィード内の自分のポストの消去
            COLLECTION_USERS.document(uid).collection("user-feed").document(postId).delete{ (error) in
                if let error = error{ completion(.failure(error)); return }
                
                print("自分のuser-feed内の自分のポストの消去に成功しました")
                
                
                //フォロワーの人それぞれのuser-feed
                Firestore.firestore().collectionGroup("user-feed")  //collectionGroupを使っている。
                    .whereField("postId", isEqualTo: postId).getDocuments { (snapshot, error) in
                        
                        if let error = error{ completion(.failure(error)); return }
                        guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
                        
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
                            completion(.success("YES"))     //successが送られるのはここからだけ
                            print("フォロワーの人のuser-feed内のポストの消去に成功しました")
                        }
                }
            }
        }
        
        //Postコレクションの中のサブコレクション(post-likesコレクション)の消去
        COLLECTION_POSTS.document(postId).collection("post-likes").getDocuments { (snapshot, error) in
            if let error = error{ completion(.failure(error)); return }
            guard let documents = snapshot?.documents else { completion(.failure(CustomError.snapShotIsNill)); return }
            
            documents.forEach { $0.reference.delete { (error) in
                if let error = error { completion(.failure(error)) }; return }}
            
            print("Postのサブコレクション(post-likesコレクション)の消去に成功しました。")
        }
        
        //後は下にある、notificationと、コメントも。できたら。。
//        let notificationQuery = COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications")
//        notificationQuery.whereField("postId", isEqualTo: postId).getDocuments { snapshot, _ in
//            guard let documents = snapshot?.documents else { return }
//            documents.forEach({ $0.reference.delete(completion: completion) })
//        }  //ここは不明
    }
}
