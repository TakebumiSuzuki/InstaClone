//
//  ValidationService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 2/10/21.
//

import UIKit

enum ValidationError: Error{
    case emailIsNil
    case invalidEmail
    case passwordNil
    case passwordLessThan6Charactors
    case fullnameNil
    case usernameNil
    case profileImageNil
}

struct ValidationService{
    
    static func validateEmail(email: String?) throws -> String{
        guard let email = email else { throw(ValidationError.emailIsNil) }
        guard email.isValidEmail() else { throw(ValidationError.invalidEmail) }
        return email
    }
    
    static func validatePassword(password: String?) throws -> String{
        guard let password = password else { throw(ValidationError.passwordNil) }
        guard password.count >= 6 else { throw(ValidationError.passwordLessThan6Charactors) }
        return password
    }
    
    static func validateFullname(fullname: String?) throws -> String{
        guard let rawFullname = fullname else { throw(ValidationError.fullnameNil) }
        let trimmedFullname = rawFullname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedFullname
    }
    
    static func validateUsername(username: String?) throws -> String{
        guard let rawUsername = username else { throw(ValidationError.usernameNil) }
        let trimmedUsername = rawUsername.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedUsername
    }
    
    static func validateProfileImage(profileImage: UIImage?) throws -> UIImage{
        guard let profileImage = profileImage else { throw(ValidationError.profileImageNil) }
        return profileImage
    }
    
}
