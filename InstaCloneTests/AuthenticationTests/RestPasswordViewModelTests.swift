//
//  RestPasswordViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/11/21.
//
@testable import InstaClone
import XCTest


class RestPasswordViewModelTests: XCTestCase {

    var sut: ResetPasswordViewModel!
    
    override func setUp(){
        super.setUp()
        sut = ResetPasswordViewModel()
        sut.email = "a"
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func test_email欄に文字が入力されている時のButtonの状態(){
        XCTAssertTrue(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.8))
        XCTAssertEqual(sut.buttonTitleColor, UIColor.white)
    }
    
    func test_email欄の文字が空の時のButtonの状態(){
        sut.email = ""
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4))
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
}
