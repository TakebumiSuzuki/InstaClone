//
//  ValidationServiceTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/10/21.
//

@testable import InstaClone
import XCTest

class ValidationServiceTests: XCTestCase {

    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_emailが妥当な時(){
        let email = "123@gmail.com"
        let valiatedEmail = try? ValidationService.validateEmail(email: email)
        XCTAssertEqual(valiatedEmail, email)
    }
    func test_emailがnilの時(){
        let expectedError = ValidationError.emailIsNil
        XCTAssertThrowsError(try ValidationService.validateEmail(email: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_emailフォーマットがinvalidの時(){
        let email = "123@gmail"
        let expectedError = ValidationError.invalidEmail
        XCTAssertThrowsError(try ValidationService.validateEmail(email: email)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_passwordが妥当な時(){
        let password = "qwerty"
        let validPassword = try? ValidationService.validatePassword(password: password)
        XCTAssertEqual(validPassword, "qwerty")
    }
    func test_passwordがnilの時(){
        let expectedError = ValidationError.passwordNil
        XCTAssertThrowsError(try ValidationService.validatePassword(password: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_passwordが6文字未満の時(){
        let password: String? = "12345"
        let expectedError = ValidationError.passwordLessThan6Charactors
        XCTAssertThrowsError(try ValidationService.validatePassword(password: password)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_fullnameが妥当な時(){
        let fullname = "  Taylor Swift   "
        let validatedFullname = try? ValidationService.validateFullname(fullname: fullname)
        XCTAssertEqual(validatedFullname, String("Taylor Swift"))
    }
    func test_fullnameがnilの時(){
        let expectedError = ValidationError.fullnameNil
        XCTAssertThrowsError(try ValidationService.validateFullname(fullname: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_usernameが妥当な時(){
        let username = " Travis  ScoTT   "
        let validatedusername = try? ValidationService.validateUsername(username: username)
        XCTAssertEqual(validatedusername, "travis  scott")
    }
    func test_usernameがnilの時(){
        let expectedError = ValidationError.usernameNil
        XCTAssertThrowsError(try ValidationService.validateUsername(username: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
    func test_profileImageが妥当な時(){
        let profileImage = UIImage(named: "instagramLogo")
        let validatedImage = try? ValidationService.validateProfileImage(profileImage: profileImage)
        XCTAssertEqual(profileImage, validatedImage)
    }
    func test_profileImageがnilの時(){
        let expectedError = ValidationError.profileImageNil
        XCTAssertThrowsError(try ValidationService.validateProfileImage(profileImage: nil)){ thrownError in
            let error = thrownError as? ValidationError
            XCTAssertEqual(error, expectedError)
        }
    }
}
