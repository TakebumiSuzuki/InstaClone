//
//  CommentService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import Firebase

class CommentService {
    
    
    //FirestoreCompletionは(Error?) -> Voidの事。
    static func uploadComment(comment: String, post: Post, user: User, completion: @escaping (FirestoreCompletion)) {

        let data: [String: Any] = ["uid": user.uid,
                                   "comment": comment,
                                   "username": user.username,
                                   "profileImageUrl": user.profileImageUrl,
                                   "timestamp": Timestamp(date: Date()),
                                   "postOwnerUid": post.ownerUid]
        
        COLLECTION_POSTS.document(post.postId).collection("comments").addDocument(data: data, completion: completion)
    }
    
    
    
    var commentListener: ListenerRegistration!
    
    func fetchComments(forPost postID: String, completion: @escaping ([Comment]) -> Void) {
        
        var comments = [Comment]()
        let query = COLLECTION_POSTS.document(postID).collection("comments")
            .order(by: "timestamp", descending: true)
        
        commentListener = query.addSnapshotListener { (snapshot, error) in
            print("-----------------Comment Listener invoked")
            if let error = error{ print("DEBUG: Error during snapshotListening: \(error.localizedDescription)"); return }
            
            comments = []
            snapshot?.documents.forEach({ document in
                let comment = Comment(dictionary: document.data())
                comments.append(comment)
            })
            completion(comments)
        }
    }
}
