//
//  SearchLogicServiceTests.swift
//  InstaCloneTests
//
//  Created by TAKEBUMI SUZUKI on 2/14/21.
//

@testable import InstaClone
import XCTest

class SearchLogicServiceTests: XCTestCase {
    
    var searchMode = true
    var active = true
    var text: String? = ""
    
    override func setUpWithError() throws {
    }
    override func tearDownWithError() throws {
        searchMode = true
        active = true
        text = ""
    }
    
    func test_SearchBarの中の文字数が０でsearchBarがnot_activeの時(){
        searchMode = false
        active = false
        text = ""
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.allPosts)
    }
    
    func test_SearchBarの中の文字数が０の時の確認(){
        searchMode = false
        active = true
        text = ""
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.allUsers)
    }
    
    func test_SearchBarの中の文字数が０でsearchBarがactiveの時(){
        searchMode = false
        active = true
        text = ""
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.allUsers)
    }
    
    func test_SearchBarの中の文字数がスペースの時(){
        searchMode = false
        active = true
        text = "  "
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.allUsers)
    }
    
    func test_SearchBarの中の文字がスペース以外の１文字の時の確認(){
        searchMode = true
        active = true
        text = "a"
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.fullnameUsername("a"))
    }
    
    func test_SearchBarの中がスペースで始まりスペースで終わる文字列の時の確認(){
        searchMode = true
        active = true
        text = "    abc  "
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.fullnameUsername("abc"))
    }
    
    func test_SearchBarの中の文字列にemailが含まれるの時の確認(){
        searchMode = true
        active = true
        text = "      abc@gmail.com  "
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.email("abc@gmail.com"))
    }
    
    func test_SearchBarの中の文字にhashtagが含まれる時の確認(){
        searchMode = true
        active = true
        text = "   #georgia  "
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.hashtag("georgia"))
    }
    
    func test_SearchBarの中の文字にmentionが含まれる時の確認(){
        searchMode = true
        active = true
        text = "  @test   "
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.mentions("test"))
    }
    
    func test_SearchBarのtextがnilの時の確認(){
        searchMode = true
        active = true
        text = nil
        let logic = SearchLogicService.searchLogicSwitcher(inSearchMode: searchMode , searchControllerIsActive: active, inputText: text)
        
        XCTAssertEqual(logic, searchLogic.searchTextIsNil)
    }
    
    
}
