//
//  CustomError.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/31/21.
//

import Foundation

public enum CustomError: Error{
    
    case dataHandling
    case snapShotIsNill
    case currentUserNil
    case uploadedImageUrlNil
    
    var localizedDescription: String{
        switch self{
        case .dataHandling:
            return "Data handling error occured in this device"
        case .snapShotIsNill:
            return "snapShot from Firestore is nil"
        case .currentUserNil:
            return "currentUser is nil"
        case .uploadedImageUrlNil:
            return "imageUrl of just uploaded picture is nil"
        }
    }
}
