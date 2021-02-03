//
//  CommentService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import Firebase

class CommentService {
    
    var commentListener: ListenerRegistration!
    
    //FirestoreCompletionを使っておけば、errorはそのまま勝手に伝えてくれる。
    static func uploadComment(comment: String, post: Post, user: User, completion: @escaping (FirestoreCompletion)) {

        let data: [String: Any] = ["uid": user.uid,
                                   "comment": comment,
                                   "timestamp": Timestamp(date: Date()),
                                   "username": user.username,
                                   "profileImageUrl": user.profileImageUrl,
                                   "postOwnerUid": post.ownerUid]
        
        COLLECTION_POSTS.document(post.postId).collection("comments").addDocument(data: data, completion: completion)
    }
    
    
    
    func fetchComments(forPost postID: String, completion: @escaping ([Comment]) -> Void) {
        
        var comments = [Comment]()
        let query = COLLECTION_POSTS.document(postID).collection("comments")
            .order(by: "timestamp", descending: true)
        
        commentListener = query.addSnapshotListener { (snapshot, error) in
            
            if let error = error{
                print("DEBUG: Error during snapshotListening...\(error.localizedDescription)")
                return
            }
            comments = []
            snapshot?.documents.forEach({ document in
                let comment = Comment(dictionary: document.data())
                comments.append(comment)
            })
            completion(comments)
        }
    }
}
