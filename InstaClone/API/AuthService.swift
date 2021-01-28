//
//  AuthService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit
import Firebase


//本来これは必須ではない。ユーザー情報を保存する前にわざわざこのstructに変換する手続きを踏む必要はない。
struct AuthCredentials {
    let email: String
    let password: String
    let fullname: String
    let username: String
    let profileImage: UIImage
}

struct AuthService {
    
    //AuthDataResultCallback型については不明。
    static func logUserIn(withEmail email: String, password: String, completion: AuthDataResultCallback?) {
        Auth.auth().signIn(withEmail: email, password: password, completion: completion)
    }
    
    
    ///UIImageをstoreに保存、Authでアカウントを作成、その他の情報をFirestoreに保存。
    static func registerUser(withCredential credentials: AuthCredentials, completion: @escaping(Error?) -> Void) {
        
        ImageUploader.uploadImage(image: credentials.profileImage) { result in
            
            switch result{
            case .failure(let error):
                completion(error)
                
            case .success(let imageUrl):
                Auth.auth().createUser(withEmail: credentials.email, password: credentials.password) { (result, error) in
                    if let error = error {
                        print("DEBUG: Failed to register user \(error.localizedDescription)")
                        completion(error)
                        return
                    }
                    
                    guard let uid = result?.user.uid else {
                        completion(CustomError.dataHandling)
                        return
                    }
                    let data: [String: Any] = ["email": credentials.email,
                                               "fullname": credentials.fullname,
                                               "profileImageUrl": imageUrl,
                                               "uid": uid,
                                               "username": credentials.username]
                    
//                    if let fcmToken = Messaging.messaging().fcmToken {
//                        data["fcmToken"] = fcmToken
//                    }
                    COLLECTION_USERS.document(uid).setData(data, completion: completion)
                }
            }
        }
    }
    
    
    ///emailを引数に、authのsendPasswordResetメソッドでリセットをかける。そこでのcompletionをそのまま引き継ぐ
    static func resetPassword(withEmail email: String, completion: SendPasswordResetCallback?) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }
}
