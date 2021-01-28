//
//  ImageUploader.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import FirebaseStorage

public enum CustomError: Error{
    
    case dataHandling
    
    var localizedDescription: String{
        switch self{
        case .dataHandling:
            return "Data handling error occured in this device"
        }
    }
}

public enum ImageKind{
    case profileImage
    case feedImage
}

struct ImageUploader {
    
    ///UIImageを引数に、それをjpeg化し、NSUUIDのファイル名でstorageに保存。downloadURLを引数にcompletion。
    static func uploadImage(image: UIImage, imageKind: ImageKind, completion: @escaping (Result<String, Error>) -> Void) {
        
        var quality = 0.0
        var path = ""
        switch imageKind{
        case .profileImage:
            quality = 0.4
            path = "/profile_images/"
        case .feedImage:
            quality = 0.75
            path = "/feed_images/"
        }
        
        guard let imageData = image.jpegData(compressionQuality: CGFloat(quality)) else {
            completion(.failure(CustomError.dataHandling))
            return
        }
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference(withPath: "\(path)\(filename)")  //ファイル名はNSUUID()で作成
        
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
