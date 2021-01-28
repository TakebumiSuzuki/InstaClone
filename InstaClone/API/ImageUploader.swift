//
//  ImageUploader.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import FirebaseStorage

public enum CustomError: String, Error{
    case dataHandling
    
    
    
    var localizedDescription: String{
        switch self{
        case .dataHandling:
            return "Data handling error occured in this device"
        
        }
    }
}

struct ImageUploader {
    
    ///UIImageを引数に、それをjpeg化し、NSUUIDのファイル名でstorageに保存。downloadURLを引数にcompletion。
    static func uploadImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(CustomError.dataHandling))
            return
        }
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference(withPath: "/profile_images/\(filename)")  //ファイル名はNSUUID()で作成
        
        ref.putData(imageData, metadata: nil) { metadata, error in
            
            if let error = error {
                print("DEBUG: Failed to upload image \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            ref.downloadURL { (url, error) in   //ここのrefの使い方チェック
                guard let imageUrl = url?.absoluteString else { return }
                completion(.success(imageUrl))
            }
        }
    }
}
