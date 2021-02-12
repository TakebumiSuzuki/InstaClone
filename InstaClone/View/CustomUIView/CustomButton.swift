//
//  CustomButton.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

public class CustomButton: UIButton{
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    
    public func setUp(title: String){
        setTitle(title, for: .normal)
        setTitleColor(UIColor(white: 1, alpha: 0.67), for: .normal)
        backgroundColor = #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4)
        layer.cornerRadius = 5
        setHeight(50)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)  //initの中に入れるとworkしない理由は不明
        isEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


