//
//  ValidationServiceTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/10/21.
//

@testable import InstaClone
import XCTest

class ValidationServiceTests: XCTestCase {

    
    func test_email欄が妥当な時(){
        let email = "123@gmail.com"
        let valiatedEmail = try? ValidationService.validateEmail(email: email)
        XCTAssertEqual(valiatedEmail, email)
    }
    func test_email欄がnilの時(){
        let expectedError = ValidationError.emailIsNil
        XCTAssertThrowsError(try ValidationService.validateEmail(email: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_email欄のフォーマットがinvalidの時(){
        let email = "123@gmail"
        let expectedError = ValidationError.invalidEmail
        XCTAssertThrowsError(try ValidationService.validateEmail(email: email)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_password欄が妥当な時(){
        let password = "qwerty"
        let validPassword = try? ValidationService.validatePassword(password: password)
        XCTAssertEqual(validPassword, "qwerty")
    }
    func test_password欄がnilの時(){
        let expectedError = ValidationError.passwordNil
        XCTAssertThrowsError(try ValidationService.validatePassword(password: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_password欄が6文字未満の時(){
        let password: String? = "12345"
        let expectedError = ValidationError.passwordLessThan6Charactors
        XCTAssertThrowsError(try ValidationService.validatePassword(password: password)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_fullname欄が妥当な時(){
        let fullname = "  Taylor Swift   "
        let validatedFullname = try? ValidationService.validateFullname(fullname: fullname)
        XCTAssertEqual(validatedFullname, String("Taylor Swift"))
    }
    func test_fullname欄がnilの時(){
        let expectedError = ValidationError.fullnameNil
        XCTAssertThrowsError(try ValidationService.validateFullname(fullname: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_username欄が妥当な時(){
        let username = " Travis  ScoTT   "
        let validatedusername = try? ValidationService.validateUsername(username: username)
        XCTAssertEqual(validatedusername, "travis  scott")
    }
    func test_username欄がnilの時(){
        let expectedError = ValidationError.usernameNil
        XCTAssertThrowsError(try ValidationService.validateUsername(username: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_profileImage欄が妥当な時(){
        let profileImage = UIImage(named: "instagramLogo")
        let validatedImage = try? ValidationService.validateProfileImage(profileImage: profileImage)
        XCTAssertEqual(profileImage, validatedImage)
    }
    func test_profileImage欄がnilの時(){
        let expectedError = ValidationError.profileImageNil
        XCTAssertThrowsError(try ValidationService.validateProfileImage(profileImage: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
}
