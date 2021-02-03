//
//  MessageViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit
import Firebase

struct MessageViewModel {
    
    init(message: Message) {
        self.message = message
    }
    let message: Message
    
    
    var messageText: String { return message.text }
    
    var chatPartnerImageUrl: URL? { return URL(string: message.chatPartnerImageUrl) }
    
    var chatPartnerName: String { return message.chatPartnerName }
    
    
    var timestampString: String? {
        let date = message.timestamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        return dateFormatter.string(from: date)
    }
    
    var messageBackgroundColor: UIColor { return message.isFromCurrentUser ? .systemGray6 : .white }
    
    var messageBorderWidth: CGFloat { return message.isFromCurrentUser ? 0 : 1.0 }
    
    var rightAnchorActive: Bool { return message.isFromCurrentUser  }
    
    var leftAnchorActive: Bool {  return !message.isFromCurrentUser }
    
    var shouldHideProfileImage: Bool { return message.isFromCurrentUser }
    
}
