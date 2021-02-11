//
//  ImageUploader.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import FirebaseStorage

enum ImageKind{
    case profileImage
    case feedImage
    var quality: CGFloat{
        switch self{
        case .profileImage: return 0.4
        case .feedImage: return 0.75
        }
    }
    var path: String{
        switch self{
        case .profileImage: return "/profile_images/"
        case .feedImage: return "/feed_images/"
        }
    }
}


struct ImageUploader {
    
    //UIImageをjpeg化。NSUUIDのファイル名でstorageに保存。completionでdownloadURLを返す。
    static func uploadImage(image: UIImage, imageKind: ImageKind, completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let imageData = image.jpegData(compressionQuality: imageKind.quality) else {
            completion(.failure(CustomError.dataHandling))
            return
        }
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference(withPath: "\(imageKind.path)\(filename)")  //ファイル名はNSUUID()で作成
        
        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error { completion(.failure(error)); return }
            
            ref.downloadURL { (url, error) in   //ここのrefの使い方チェック
                guard let imageUrl = url?.absoluteString else { completion(.failure(CustomError.uploadedImageUrlNil)); return}
                
                completion(.success(imageUrl))
            }
        }
    }
}
