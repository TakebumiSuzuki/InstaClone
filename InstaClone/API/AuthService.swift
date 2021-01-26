//
//  AuthService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit
import Firebase

struct AuthCredentials {   //これは必須ではないと言っていた。確かにユーザー情報を保存する前にわざわざstructに変換する必要はない。
    let email: String
    let password: String
    let fullname: String
    let username: String
    let profileImage: UIImage
}

struct AuthService {
    
    ///emailとpasswordを引数にログイン。AuthのsignInメソッドのcompletionをそのままcompletionにして引き継ぐ。AuthDataResultCallback型については不明。
    static func logUserIn(withEmail email: String, password: String, completion: AuthDataResultCallback?) {
        Auth.auth().signIn(withEmail: email, password: password, completion: completion)
    }
    
    ///カスタムで作ったcredentialsオブジェクトを引数に、UIImageをstoreに保存、Authでアカウントを作成、その他の情報をfirestoreのusersコレクションに保存。
    static func registerUser(withCredential credentials: AuthCredentials, completion: @escaping(Error?) -> Void) {
        
        ImageUploader.uploadImage(image: credentials.profileImage) { imageUrl in
            
            Auth.auth().createUser(withEmail: credentials.email, password: credentials.password) { (result, error) in
                if let error = error {
                    print("DEBUG: Failed to register user \(error.localizedDescription)")
                    return
                }
                
                guard let uid = result?.user.uid else { return }
                
                var data: [String: Any] = ["email": credentials.email,
                                           "fullname": credentials.fullname,
                                           "profileImageUrl": imageUrl,
                                           "uid": uid,
                                           "username": credentials.username]
                
                if let fcmToken = Messaging.messaging().fcmToken {
                    data["fcmToken"] = fcmToken
                }
                
                COLLECTION_USERS.document(uid).setData(data, completion: completion)
            }
        }
    }
    
    ///emailを引数に、authのsendPasswordResetメソッドでリセットをかける。そこでのcompletionをそのまま引き継ぐ
    static func resetPassword(withEmail email: String, completion: SendPasswordResetCallback?) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }
}
