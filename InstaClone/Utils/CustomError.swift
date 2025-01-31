//
//  CustomError.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/31/21.
//#imageLiteral(resourceName: "simulator_screenshot_2985EDDA-45E3-43D0-9A52-A453EC5C0F7E.png")

import Foundation

public enum CustomError: Error, Equatable{
    
    case dataHandling
    case snapShotIsNill
    case currentUserNil
    case uploadedImageUrlNil
    case postLikeIsMinus
    case noUserExists
    
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
        case .postLikeIsMinus:
            return "post like number is minus"
        case .noUserExists:
            return "There is no user exists"
        }
    }
}
