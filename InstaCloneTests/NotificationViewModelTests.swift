//
//  NotificationViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/13/21.
//

@testable import InstaClone
@testable import Firebase
import XCTest


class NotificationViewModelTests: XCTestCase {
    
    var sut: NotificationViewModel!
    var notification: InstaClone.Notification!
    var data: [String: Any]!
    
    override func setUp(){
        super.setUp()
        data = ["type": 0,
                "id": "sampleId",
                "uid": "sampleUid",
                "username": "sampleUsername",
                "userProfileImageUrl": "www.sample.com",
                "timestamp": Timestamp(date: Date(timeIntervalSinceReferenceDate: 10000)),
                "postId": "samplePostId",
                "postImageUrl": "www.sampleImageUrl.com"
        ]
        notification = Notification(dictionary: data)
        sut = NotificationViewModel(notification: notification)
    }
    override func tearDown(){
        super.tearDown()
        sut = nil
    }
    
    func test_postImageUrlがちゃんと取得できるかの確認(){
        let expectedResult = URL(string: notification.postImageUrl!)!
        XCTAssertEqual(sut.postImageUrl, expectedResult)
    }
    func test_profileImageUrlがちゃんと取得できるかの確認(){
        let expectedResult = URL(string: notification.userProfileImageUrl)!
        XCTAssertEqual(sut.profileImageUrl, expectedResult)
    }
    func test_timestampStringとnotificationMessageがちゃんと取得できるかの確認(){
        let expectedResult1 = TimestampService.getStringDate(timeStamp: notification.timestamp, unitsStyle: .abbreviated)
        XCTAssertEqual(sut.timestampString, expectedResult1)
        
        let username = notification.username
        let message = notification.type.notificationMessage
        
        let attributedText = NSMutableAttributedString(string: username, attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: message, attributes: [.font: UIFont.systemFont(ofSize: 14)]))
        attributedText.append(NSAttributedString(string: "  \(expectedResult1 ?? "") ago", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.lightGray]))

        let expectedResult2 = attributedText
        
        XCTAssertEqual(sut.notificationMessage, expectedResult2)
    }
    
    func test_typeがlikeの時shouldHidePostImageがちゃんと取得できるかの確認(){
        data["type"] = 0
        notification = InstaClone.Notification(dictionary: data)
        sut.notification = notification
        XCTAssertFalse(sut.shouldHidePostImage)
    }
    func test_typeがfollowの時shouldHidePostImageがちゃんと取得できるかの確認(){
        data["type"] = 1
        notification = InstaClone.Notification(dictionary: data)
        sut.notification = notification
        XCTAssertTrue(sut.shouldHidePostImage)
    }
    func test_typeがcommentの時shouldHidePostImageがちゃんと取得できるかの確認(){
        data["type"] = 2
        notification = InstaClone.Notification(dictionary: data)
        sut.notification = notification
        XCTAssertFalse(sut.shouldHidePostImage)
    }
    func test_userIsFollowedがtrueの時buttonプロパティーがちゃんと取得できるかの確認(){
        notification.userIsFollowed = true
        sut = NotificationViewModel(notification: notification)
        XCTAssertEqual(sut.followButtonText, "Following")
        XCTAssertEqual(sut.followButtonBackgroundColor, UIColor.white)
        XCTAssertEqual(sut.followButtonTextColor, UIColor.black)
    }
    func test_userIsFollowedがfalseの時buttonプロパティーがちゃんと取得できるかの確認(){
        notification.userIsFollowed = false
        sut = NotificationViewModel(notification: notification)
        XCTAssertEqual(sut.followButtonText, "Follow")
        XCTAssertEqual(sut.followButtonBackgroundColor, UIColor.systemBlue)
        XCTAssertEqual(sut.followButtonTextColor, UIColor.white)
    }
    
    
    
}
