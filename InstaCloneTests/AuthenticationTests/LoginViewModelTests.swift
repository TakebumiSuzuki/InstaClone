//
//  LoginViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/6/21.
//

@testable import InstaClone
import XCTest

class LoginViewModelTests: XCTestCase {
    
    var sut: LoginViewModel!
    
    override func setUp() {
        super.setUp()
        sut = LoginViewModel()
    }
    override func tearDown() {
        super.setUp()
        sut = nil
    }
    
    func test_email欄とpassword欄両方に入力ありの時のButtonの状態(){
        sut.email = "a"
        sut.password = "a"
        XCTAssertTrue(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.8))
        XCTAssertEqual(sut.buttonTitleColor, .white)
    }
    func test_email欄に入力ありpasswordは空の時のButtonの状態(){
        sut.email = "a"
        sut.password = ""
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4) )
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
    func test_email欄は空passwordに入力ありの時のButtonの状態(){
        sut.email = ""
        sut.password = "a"
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4) )
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
    func test_email欄とpassword欄両方が空の時のButtonの状態(){
        sut.email = ""
        sut.password = ""
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4) )
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
    
}
