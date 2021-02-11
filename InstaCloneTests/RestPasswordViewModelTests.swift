//
//  RestPasswordViewModelTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/11/21.
//
@testable import InstaClone
import XCTest
import UIKit

class RestPasswordViewModelTests: XCTestCase {

    var sut: ResetPasswordViewModel!
    
    override func setUpWithError() throws {
        sut = ResetPasswordViewModel()
        sut.email = "a"
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func test_emailに文字が入力されている時(){
        XCTAssertTrue(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1))
        XCTAssertEqual(sut.buttonTitleColor, UIColor.white)
    }
    
    func test_emailの文字が空の時(){
        sut.email = ""
        XCTAssertFalse(sut.formIsValid)
        XCTAssertEqual(sut.buttonBackgroundColor, #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1).withAlphaComponent(0.5))
        XCTAssertEqual(sut.buttonTitleColor, UIColor(white: 1, alpha: 0.67))
    
    }
}
