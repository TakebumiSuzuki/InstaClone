//
//  AuthServiceTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/12/21.
//

import XCTest
@testable import InstaClone
@testable import Firebase

class AuthServiceTests: XCTestCase {

    var sut: AuthService!
    var clientMock: AuthApiClient!
    var testExcuted = false
    
    override func setUp(){
        super.setUp()
        testExcuted = false
    }

    override func tearDown(){
        super.tearDown()
        sut = nil
        clientMock = nil
    }
    
    func test_signInメソッドの動作確認_errorが返ってきた時(){
        clientMock = ClientMock(result: nil, error: AuthApiMockError.fakeError)
        sut = AuthService(client: clientMock)
        
        sut.logUserIn(withEmail: "placeHolder", password: "placeHolder") { (result, error) in
            self.testExcuted = true
            
            XCTAssertTrue(self.testExcuted)
            XCTAssertNil(result)
            XCTAssertNotNil(error)
        }
    }
    
    func test_sendPasswordResetメソッドの動作確認_エラーにならなかった時(){
        clientMock = ClientMock(result: nil, error: nil)  //こちらのメソッドでは引数resultは使っていないので関係ない。errorのみが関係する。
        sut = AuthService(client: clientMock)
        
        sut.resetPassword(withEmail: "placeHolder") { (error) in
            self.testExcuted = true
            
            XCTAssertTrue(self.testExcuted)
            XCTAssertNil(error)
        }
    }
    
    func test_sendPasswordResetメソッドの動作確認_errorが返ってきた時(){
        clientMock = ClientMock(result: nil, error: AuthApiMockError.fakeError)  //こちらのメソッドでは引数resultは使っていないので関係ない。errorのみが関係する。
        sut = AuthService(client: clientMock)
        
        sut.resetPassword(withEmail: "placeHolder") { (error) in
            self.testExcuted = true
            
            XCTAssertTrue(self.testExcuted)
            XCTAssertNotNil(error)
        }
    }
}


//Auth.auth()の代わりとなるMockオブジェクトの定義-------------------------------------------------------------
class ClientMock: AuthApiClient{
    
    var result: AuthDataResult?
    var error: Error?
    init(result: AuthDataResult?, error: Error?) {
        self.result = result
        self.error = error
    }
    
    public func signIn(withEmail: String, password: String, completion: ((AuthDataResult?, Error?) -> Void)?) {
        completion!(result, error)
    }
    public func sendPasswordReset(withEmail: String, completion: ((Error?) -> Void)?) {
       completion!(error)
    }
}

//テストの戻り値で使うためのフェイクのErrorオブジェクトの定義--------------------------------------------------------
enum AuthApiMockError: Error, Equatable{
    case fakeError
}
