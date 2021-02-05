//
//  UserCellViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import Foundation

struct UserCellViewModel {
    
    init(user: User) {
        self.user = user
    }
    let user: User
    
    var profileImageUrl: URL? { return URL(string: user.profileImageUrl) }
    var username: String { return user.username }
    var fullname: String { return user.fullname }
    
    
}
