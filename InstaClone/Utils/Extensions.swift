//
//  Extensions.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit
import JGProgressHUD
import Firebase

//MARK: - UIViewControllerの機能拡張。1.hud付け替え機能 2.gradient layer 3.簡単なalertの表示機能をつける。
extension UIViewController {
    
    static let hud = JGProgressHUD(style: .dark)
    
    func showLoader(_ show: Bool) {  //UICollectionViewControllernの場合でもちゃんと働くのか疑問
        view.endEditing(true)
        
        if show {
            UIViewController.hud.show(in: view)
        } else {
            UIViewController.hud.dismiss()
        }
    }
    
    func configureGradientLayer() {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.systemPurple.cgColor, UIColor.systemBlue.cgColor]
        gradient.locations = [0, 1]
        view.layer.addSublayer(gradient)
        gradient.frame = view.frame
    }
    
    func showMessage(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showSimpleAlert(title: String, message: String, actionTitle: String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
}

extension UITextField {
    func disableAutoFill() {
        if #available(iOS 12, *) {
            textContentType = .oneTimeCode
        } else {
            textContentType = .init(rawValue: "")
        }
    }
}

extension String{
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    
    func getHashtags() -> [String]{
        if let regex = try? NSRegularExpression(pattern: "#[\\p{L}0-9_]*", options: .caseInsensitive){
            
            let string = self as NSString
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                string.substring(with: $0.range).replacingOccurrences(of: "#", with: "").lowercased()
            }
        }
        return []
    }
    
    func resolveEmails() -> String?{
        let nsText: NSString = self as NSString
        let words: [String] = nsText.components(separatedBy: " ")
        var detectedWords:[String] = []
        for word in words{
            if word.isValidEmail(){  //上に書いた別のExtensionメソッド
                detectedWords.append(word)
            }
        }
        return detectedWords.first
    }
    
    func resolveHashtags() -> String?{
        let nsText: NSString = self as NSString
        let words: [String] = nsText.components(separatedBy: " ")
        var detectedWords:[String] = []
        for word in words{
            if word.hasPrefix("#"){
                let rawString = String(word.dropFirst())
                detectedWords.append(rawString)
            }
        }
        return detectedWords.first
    }
    
    func resolveMentions() -> String?{
        let nsText: NSString = self as NSString
        let words: [String] = nsText.components(separatedBy: " ")
        var detectedWords:[String] = []
        for word in words{
            if word.hasPrefix("@"){
                let rawString = String(word.dropFirst())
                detectedWords.append(rawString)
            }
        }
        return detectedWords.first
    }
    
}


//MARK: - UIButtonの機能拡張。ボタン中の文字をattributedTextにする
extension UIButton {
    
    func attributedTitle(firstPart: String, secondPart: String) {
        let atts: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(white: 1, alpha: 0.87), .font: UIFont.systemFont(ofSize: 16)]
        let attributedTitle = NSMutableAttributedString(string: "\(firstPart) ", attributes: atts)
        
        let boldAtts: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(white: 1, alpha: 0.87), .font: UIFont.boldSystemFont(ofSize: 16)]
        attributedTitle.append(NSAttributedString(string: secondPart, attributes: boldAtts))
        
        setAttributedTitle(attributedTitle, for: .normal)
    }
}



extension UIAlertController {   //constraintエラーが出るバグをなくすためだけのコード
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        pruneNegativeWidthConstraints()
    }

    private func pruneNegativeWidthConstraints() {
        for subView in self.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}

