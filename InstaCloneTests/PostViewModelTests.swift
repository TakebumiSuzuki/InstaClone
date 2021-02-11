//
//  PostViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/11/21.
//

import XCTest
import UIKit
@testable import InstaClone
@testable import Firebase
@testable import ActiveLabel

class PostViewModelTests: XCTestCase{
    
    var sut: PostViewModel!
    var post: Post!
    
    let data: [String: Any] = [
        "postId":"samplePostID",
        "ownerUid":"sampleOwnerUid",
        "ownerImageUrl":"www.testImageUrl.com",
        "ownerUsername":"sampleName",
        "imageUrl":"www.testUrl.com",
        "likes": 10,
        "caption":"sampleCaption",
        "timestamp": Timestamp(date: Date(timeIntervalSince1970: 100000)),
        "hashtags": ["sample", "tag"],
        "didLike": false ]
    
    
    override func setUpWithError() throws {
        post = Post(dictionary: data)
        sut = PostViewModel(post: post)
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }

    func test_sutとpostのインスタンス化確認(){
        XCTAssertNotNil(post)
        XCTAssertNotNil(sut)
    }
    func test_usernameの確認(){
        XCTAssertEqual(sut.username, "sampleName")
    }
    func test_userProfileImageUrlの確認(){
        XCTAssertEqual(sut.userProfileImageUrl, URL(string: "www.testImageUrl.com")!)
    }
    func test_imageUrlの確認(){
        XCTAssertEqual(sut.imageUrl, URL(string: "www.testUrl.com")!)
    }
    func test_likesの確認(){
        XCTAssertEqual(sut.likes, 10)
    }
    func test_likeButtonTintColorとlikeButtonImageの確認_didLikeがtrueの時の(){
        sut.post.didLike = true
        XCTAssertEqual(sut.likeButtonTintColor, UIColor.red)
        XCTAssertEqual(sut.likeButtonImage, UIImage(named: "like_selected"))
    }
    func test_likeButtonTintColorとlikeButtonImageの確認_didLikeがfalseの時(){
        sut.post.didLike = false
        XCTAssertEqual(sut.likeButtonTintColor, UIColor.black)
        XCTAssertEqual(sut.likeButtonImage, UIImage(named: "like_unselected"))
    }
    func test_likesLabelTextの確認_likesが1の時(){
        sut.post.likes = 1
        XCTAssertEqual(sut.likesLabelText, "1 like")
    }
    func test_likesLabelTextの確認_likesが1以外の時(){
        sut.post.likes = 0
        XCTAssertEqual(sut.likesLabelText, "0 likes")
        sut.post.likes = 2
        XCTAssertEqual(sut.likesLabelText, "2 likes")
    }
    func test_captionの確認(){
        XCTAssertEqual(sut.caption, "sampleCaption")
    }
    func test_timestampStringの確認(){
        let expectedString = TimestampService.getStringDate(timeStamp: Timestamp(date: Date(timeIntervalSince1970: 100000)), unitsStyle: .full)
        XCTAssertEqual(sut.timestampString, expectedString)
    }
    
}
