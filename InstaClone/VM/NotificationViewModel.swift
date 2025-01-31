//
//  NotificationViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

struct NotificationViewModel {
    
    var notification: Notification
    init(notification: Notification) {
        self.notification = notification
    }
    
    
    var postImageUrl: URL? { return URL(string: notification.postImageUrl ?? "") }
    
    var profileImageUrl: URL? { return URL(string: notification.userProfileImageUrl) }
    
    var timestampString: String? {
        return TimestampService.getStringDate(timeStamp: notification.timestamp, unitsStyle: .abbreviated)
    }
    
    var notificationMessage: NSAttributedString {
        let username = notification.username
        let message = notification.type.notificationMessage
        
        let attributedText = NSMutableAttributedString(string: username, attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: message, attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        attributedText.append(NSAttributedString(string: "  \(timestampString ?? "") ago", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.lightGray]))
        
        return attributedText
    }
    
    var shouldHidePostImage: Bool { return notification.type == .follow }
    
    var followButtonText: String {
        return notification.userIsFollowed ? "Following" : "Follow"  //userIsFollowedはローカルで後から代入されるプロパティ
    }
    
    var followButtonBackgroundColor: UIColor {
        return notification.userIsFollowed ? .white: .systemBlue
    }
    
    var followButtonTextColor: UIColor {
        return notification.userIsFollowed ? .black : .white
    }
}
