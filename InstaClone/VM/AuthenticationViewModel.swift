//
//  AuthenticationViewModel.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

//必須ではない。
protocol AuthenticationViewModel {
    var formIsValid: Bool { get }
    var buttonBackgroundColor: UIColor { get }
    var buttonTitleColor: UIColor { get }
}


struct LoginViewModel: AuthenticationViewModel {
    
    var email: String?
    var password: String?
    
    var formIsValid: Bool {  //emailとpassword両方に何か打ち込まれていたらtrue
        return email?.isEmpty == false && password?.isEmpty == false
    }
    
    var buttonBackgroundColor: UIColor {
        return formIsValid ? #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.8) : #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4)
    }
    
    var buttonTitleColor: UIColor {
        return formIsValid ? .white : UIColor(white: 1, alpha: 0.67)
    }
}


struct RegistrationViewModel: AuthenticationViewModel {
    
    var email: String?
    var password: String?
    var fullname: String?
    var username: String?
    
    var formIsValid: Bool {
        return email?.isEmpty == false && password?.isEmpty == false
            && fullname?.isEmpty == false && username?.isEmpty == false
            && fullname!.count >= 2 && fullname!.count <= 20
            && username!.count >= 2 && username!.count <= 20
    }
    
    var buttonBackgroundColor: UIColor {
        return formIsValid ? #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.8) : #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4)
    }
    
    var buttonTitleColor: UIColor {
        return formIsValid ? .white : UIColor(white: 1, alpha: 0.67)
    }
}


struct ResetPasswordViewModel: AuthenticationViewModel {
    
    var email: String?

    var formIsValid: Bool { return email?.isEmpty == false }
    
    var buttonBackgroundColor: UIColor {
        formIsValid ? #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.8) : #colorLiteral(red: 1, green: 0.135659839, blue: 0.8787164696, alpha: 1).withAlphaComponent(0.4)
    }
    
    var buttonTitleColor: UIColor {
        return formIsValid ? .white : UIColor(white: 1, alpha: 0.67)
    }
}
