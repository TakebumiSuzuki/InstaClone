//
//  RegistrationViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/11/21.
//
@testable import InstaClone
import XCTest
import UIKit

class RegistrationViewModelTests: XCTestCase {

    var sut: RegistrationViewModel!
    
    override func setUpWithError() throws {
        sut = RegistrationViewModel()
        sut.email = "a"
        sut.password = "a"
        sut.fullname = "aa"
        sut.username = "aa"
    }
    override func tearDownWithError() throws {
        sut = nil
    }

    
    func test_全てのtextFieldに文字が入力されている時(){
        XCTAssertTrue(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1))
        XCTAssertEqual(sut.buttonTitleColor, UIColor.white)
    }
    func test_emilがemptyの時(){
        sut.email = ""
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5))
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
    func test_passwordがemptyの時(){
        sut.password = ""
        XCTAssertFalse(sut.formIsValid)
    }
    func test_fullnameがemptyの時(){
        sut.fullname = ""
        XCTAssertFalse(sut.formIsValid)
    }
    func test_usernameがemptyの時(){
        sut.username = ""
        XCTAssertFalse(sut.formIsValid)
    }
    func test_fullnameの文字数が2より小さい時(){
        sut.fullname = "a"
        XCTAssertFalse(sut.formIsValid)
    }
    func test_fullnameの文字数が20より大きい時(){
        sut.fullname = "This line has 21 char"
        XCTAssertTrue(sut.fullname!.count == 21)
        XCTAssertFalse(sut.formIsValid)
    }
    func test_usernameの文字数が2より小さい時(){
        sut.username = "a"
        XCTAssertFalse(sut.formIsValid)
    }
    func test_usernameの文字数が20より大きい時(){
        sut.username = "This line has 21 char"
        XCTAssertTrue(sut.username!.count == 21)
        XCTAssertFalse(sut.formIsValid)
    }
    
}
