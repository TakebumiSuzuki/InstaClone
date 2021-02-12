//
//  ImageUploaderTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/12/21.
//

@testable import InstaClone
@testable import Firebase
import XCTest

class ImageUploaderTests: XCTestCase {

    func test_uploadImageメソッド_妥当な写真アップロード(){
        
        let expect = expectation(description: "Uploading Valid Image")
        var url: String? = nil
        
        ImageUploader.uploadImage(image: UIImage(systemName: "person")!, imageKind: .feedImage) { (result) in
            switch result{
            case .success(let imageUrl):
                url = imageUrl
                expect.fulfill()
            case .failure(let error):
                XCTFail("Failuer in API Client. \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 3) { (error) in
            if let error = error{
                print(error.localizedDescription)
                XCTFail("ExpectaionTimeOut")
                return
            }
        }
        XCTAssertNotNil(url)
    }
    
}
