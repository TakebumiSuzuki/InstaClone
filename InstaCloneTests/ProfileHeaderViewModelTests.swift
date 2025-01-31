//
//  ProfileHeaderViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/11/21.
//

@testable import InstaClone
import XCTest

class ProfileHeaderViewModelTests: XCTestCase {

    var sut: ProfileHeaderViewModel!
    var stats: UserStats!
    var data: [String: Any] = ["email": "123@gmail.com",
                               "fullname": "Taro Yamada",
                               "profileImageUrl": "www.google.com",
                               "username": "taro",
                               "uid": "111",
                               "isFollowed": true]
    
    override func setUp(){
        super.setUp()
        stats = UserStats(followers: 2, following: 3, posts: 4)
        let user = User(dictionary: data)
        user.stats = stats
        sut = ProfileHeaderViewModel(user: user)
    }

    override func tearDown(){
        super.tearDown()
        sut = nil
    }
    
    func test_Userがインスタンス化されている事の確認(){
        XCTAssertNotNil(sut.user)
    }
    func test_profileImageUrlがちゃんと取得できるかの確認(){
        XCTAssertEqual(sut.profileImageUrl, URL(string: "www.google.com"))
    }
    func test_fullnameがちゃんと取得できるかの確認(){
        XCTAssertEqual(sut.fullname, "Taro Yamada")
    }
    func test_numberOfFollowersがちゃんと取得できるかの確認(){
        let expectedResult = sut.attributedStatText(value: 2, label: "followers")
        XCTAssertEqual(sut.numberOfFollowers, expectedResult)
    }
    func test_numberOfFollowingがちゃんと取得できるかの確認(){
        let expectedResult = sut.attributedStatText(value: 3, label: "following")
        XCTAssertEqual(sut.numberOfFollowing, expectedResult)
    }
    func test_numberOfPostsがちゃんと取得できるかの確認(){
        let expectedResult = sut.attributedStatText(value: 4, label: "posts")
        XCTAssertEqual(sut.numberOfPosts, expectedResult)
    }
}
