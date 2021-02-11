//
//  LoginViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/6/21.
//

@testable import InstaClone
@testable import Firebase
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
    
    func test_emailとpassword両方に入力あり(){
        sut.email = "a"
        sut.password = "a"
        XCTAssertTrue(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1) )
        XCTAssertEqual(sut.buttonTitleColor, .white)
    }
    func test_emailに入力ありpasswordは空(){
        sut.email = "a"
        sut.password = ""
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5) )
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
    func test_emailは空passwordに入力あり(){
        sut.email = ""
        sut.password = "a"
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5) )
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
    func test_emailとpassword両方が空(){
        sut.email = ""
        sut.password = ""
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5) )
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    }
    
}
