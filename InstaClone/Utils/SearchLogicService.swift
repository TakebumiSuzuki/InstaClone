//
//  SearchLogicService.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 2/14/21.
//

import UIKit

enum searchLogic: Equatable{
    case allPosts
    case allUsers
    case fullnameUsername(String)
    case email(String)
    case hashtag(String)
    case mentions(String)
    case searchTextIsNil
}


struct SearchLogicService{
    
    static func searchLogicSwitcher(inSearchMode: Bool, searchControllerIsActive: Bool, inputText: String?) -> searchLogic{
        
        if !inSearchMode{
            if !searchControllerIsActive{  //firstResponderになっていない時。つまり.allの初期画面かcancelボタンを押した直後。→全Post表示。
                return .allPosts
            }else{                          //firstResponderになっている時で、かつ文字がスペースのみ(空文字)の時。→全ユーザー表示
                return .allUsers
            }
        }
        
        if inSearchMode{    //以下は実際に文字が打ち込まれてサーチ状態になっている時。
            guard let rawText = inputText else { return .searchTextIsNil }
            let text = rawText.trimmingCharacters(in: .whitespaces)
            
            
            if text.count < 2{    //ここはつまりは一文字のみが打ち込まれている場合。フルネームとユーザーネーム両方から検索
                return .fullnameUsername(text)
            }
            if let detectedEmail = text.resolveEmails(){  //emailから検索。
                return .email(detectedEmail)
            }else if let detectedHashtag = text.resolveHashtags(){  //ここのみAPIを使う。
                return .hashtag(detectedHashtag)
            }else if let detectedMention = text.resolveMentions(){  //ユーザーネームからのみ検索
                return .mentions(detectedMention)
            }else{  //フルネームとユーザーネーム両方から検索
                return  .fullnameUsername(text)
            }
        }
        return .searchTextIsNil
    }
}
