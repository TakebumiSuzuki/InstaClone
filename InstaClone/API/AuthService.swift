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
    
    ///UIImageをstoreに保存、Authでアカウントを作成、その他の情報をFirestoreに保存。
    static func registerUser(withCredential credentials: AuthCredentials, completion: @escaping (Error?) -> Void) {
        
        ImageUploader.uploadImage(image: credentials.profileImage, imageKind: .profileImage) { (result) in
            switch result{
            case .failure(let error):
                completion(error)
            case .success(let imageUrl):
                AuthService.createUser(credentials: credentials, imageUrl: imageUrl) { (error) in
                    completion(error)
                }
            }
        }
    }
    
    private static func createUser(credentials: AuthCredentials, imageUrl: String, completion: @escaping (Error?) -> Void){
        
        Auth.auth().createUser(withEmail: credentials.email, password: credentials.password) { (result, error) in
            if let error = error {
                print("DEBUG: Failed to register user: \(error.localizedDescription)")
                completion(error)
                return
            }
            guard let uid = result?.user.uid else { completion(CustomError.dataHandling); return }
            
            let data: [String: Any] = ["email": credentials.email,
                                       "fullname": credentials.fullname,
                                       "profileImageUrl": imageUrl,
                                       "uid": uid,
                                       "username": credentials.username]
            
//            if let fcmToken = Messaging.messaging().fcmToken {
//                data["fcmToken"] = fcmToken
//            }
            COLLECTION_USERS.document(uid).setData(data) { (error) in
                if let error = error{
                    print("DEBUG: Failed to save user data to Firestore: \(error.localizedDescription)")
                    completion(error)
                }
                completion(nil)
            }
        }
    }
    
    //MARK: - 以下はMockを使ってTestをしている。
    var client: AuthApiClient
    init(client: AuthApiClient) {
        self.client = client
    }
    
    func logUserIn(withEmail email: String, password: String, completion: @escaping AuthDataResultCallback) {
        
        client.signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error{
                completion(nil, error)
                return
            }
            completion(authResult, nil)
        }
    }
    
    
    func resetPassword(withEmail email: String, completion: @escaping SendPasswordResetCallback) {
        client.sendPasswordReset(withEmail: email) { (error) in
            if let error = error{
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
}
    

extension Auth: AuthApiClient{
    //プロトコルに準拠したのでこれ以上書くことはない。
}
    
protocol AuthApiClient{
    func signIn(withEmail: String, password: String, completion: ((AuthDataResult?, Error?) -> Void)?)
    func sendPasswordReset(withEmail: String, completion: ((Error?) -> Void)?)
}

