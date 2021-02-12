//
//  UserServiceTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/12/21.
//

@testable import InstaClone
@testable import Firebase
import XCTest

class UserServiceTests: XCTestCase {
    
    var sampleUser: InstaClone.User!  //どこかでUserが別に定義されているっぽいのでModuleNameをつけてエラーを回避している。
    
    
    func test_fetchUserメソッド_実在するuidを使ってfetchした時(){
        let expect = expectation(description: "Fetching User object")
        
        UserService.fetchUser(withUid: "P0d0M2VtSuYebyeYXJ3NEFrHWCD2") { (result) in //kirinのuidを使って調べる。
            switch result{
            case .failure(let error):
                XCTFail("Error: \(error.localizedDescription)")
            case .success(let user):
                self.sampleUser = user
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertEqual(sampleUser.username, "kirin")
    }
    
    
    func test_fetchUserメソッド_実在しないuidを使ってfetchした時(){
        let expect = expectation(description: "Fetching User object")
        
        UserService.fetchUser(withUid: "wrongUID") { (result) in
            switch result{
            case .failure(_):
                expect.fulfill()
            case .success(let user):
                self.sampleUser = user
                XCTFail("Error")
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

}
