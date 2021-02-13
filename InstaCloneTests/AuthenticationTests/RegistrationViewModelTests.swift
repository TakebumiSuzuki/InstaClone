//
//  RegistrationViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/11/21.
//
@testable import InstaClone
import XCTest


class RegistrationViewModelTests: XCTestCase {

    var sut: RegistrationViewModel!
    
    override func setUp() {
        super.setUp()
        sut = RegistrationViewModel()
        sut.email = "a"
        sut.password = "a"
        sut.fullname = "aa"
        sut.username = "aa"
    }
    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    
    func test_全てのtextField欄に文字が入力されている時のButtonの状態(){
        XCTAssertTrue(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.8))
        XCTAssertEqual(sut.buttonTitleColor, UIColor.white)
    }
    func test_emil欄がemptyの時のButtonの状態(){
        sut.email = ""
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4))
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
    func test_password欄がemptyの時のButtonのActive状態(){
        sut.password = ""
        XCTAssertFalse(sut.formIsValid)
    }
    func test_fullname欄がemptyの時のButtonのActive状態(){
        sut.fullname = ""
        XCTAssertFalse(sut.formIsValid)
    }
    func test_username欄がemptyの時のButtonのActive状態(){
        sut.username = ""
        XCTAssertFalse(sut.formIsValid)
    }
    func test_fullname欄の文字数が2より小さい時のButtonのActive状態(){
        sut.fullname = "a"
        XCTAssertFalse(sut.formIsValid)
    }
    func test_fullname欄の文字数が20より大きい時のButtonのActive状態(){
        sut.fullname = "This line has 21 char"
        XCTAssertTrue(sut.fullname!.count == 21)
        XCTAssertFalse(sut.formIsValid)
    }
    func test_username欄の文字数が2より小さい時のButtonのActive状態(){
        sut.username = "a"
        XCTAssertFalse(sut.formIsValid)
    }
    func test_username欄の文字数が20より大きい時のButtonのActive状態(){
        sut.username = "This line has 21 char"
        XCTAssertTrue(sut.username!.count == 21)
        XCTAssertFalse(sut.formIsValid)
    }
    
}
