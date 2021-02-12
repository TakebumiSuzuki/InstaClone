//
//  LoginController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit  //ログイン関係はAuthServiceで行うのでここにFirebaseをimportする必要はないという事
import Firebase
//MainTabController上で実行される。ログイン成功後に画面を閉じ、さらにUserオブジェクトをfetchして情報を新しいユーザーに切り替える為のメソッド。
protocol AuthenticationDelegate: class {
    func authenticationDidComplete()
}

class LoginController: UIViewController {
    
    // MARK: - Properties
    
    private var viewModel = LoginViewModel()
    weak var delegate: AuthenticationDelegate?  //ログイン成功した後に画面を閉じさせるためのプロトコル
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: #imageLiteral(resourceName: "Logo"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let emailTextField: CustomTextField = {
        let tf = CustomTextField(placeholder: "Email")
        tf.textContentType = .emailAddress
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.returnKeyType = .next
        return tf
    }()
    
    private let passwordTextField: UITextField = {
        let tf = CustomTextField(placeholder: "Password")
        tf.textContentType = .password
        tf.isSecureTextEntry = true
        tf.disableAutoFill()
        tf.returnKeyType = .done
        return tf
    }()
    
    private lazy var loginButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setUp(title: "Log In")
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()
        
    private lazy var forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        //attributedTitleはExtensions.swift内で機能拡張している
        button.attributedTitle(firstPart: "Forgot your password?", secondPart: "Get help signing in.")
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.addTarget(self, action: #selector(handleShowResetPassword), for: .touchUpInside)
        return button
    }()
    
    private lazy var dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.attributedTitle(firstPart: "Don't have an account?", secondPart: "Sign Up")
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureTextFields()     //UIControlクラスのaddTarget Method
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    deinit {
        print("------------------Login Controller being DEINITIALIZED-------------------")
    }
    
    // MARK: - Helpers
    
    private func configureUI() {
        
        configureGradientLayer()    //viewControllerのextension
        
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black  //これを書くとstatus barが白字になる
        
        view.addSubview(iconImageView)
        iconImageView.centerX(inView: view)
        iconImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        iconImageView.setHeight(80)
        iconImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        let stack = UIStackView(arrangedSubviews: [emailTextField, passwordTextField,
                                                   loginButton, forgotPasswordButton])
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.anchor(top: iconImageView.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 30)
    }
    
    private func configureTextFields() {  //それぞれの行をprivate letのコンストラクタの中に入れても動く
        emailTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    
    // MARK: - Actions
    
    @objc private func handleLogin() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard email.isValidEmail() else{
            showSimpleAlert(title: "Email isn't in correct format.", message: "", actionTitle: "ok")
            return
        }
        
        showLoader(true)
        let auth = Auth.auth()
        let authService = AuthService(client: auth)
        authService.logUserIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                self.showLoader(false)
                print("DEBUG: Failed to log user in: \(error.localizedDescription)")
                self.showSimpleAlert(title: "", message: error.localizedDescription, actionTitle: "ok")
                return
            }
            self.showLoader(false)
            self.delegate?.authenticationDidComplete()
        }
    }
    
    @objc private func handleShowResetPassword() {
        guard let email = emailTextField.text else{ return } //リセットページに遷移してもそこに入力済みのemailがそのまま表示されるように
        let vc = ResetPasswordController(email: email)
        vc.delegate = self  //一番下のdelegate methodの為の設定。ResetPassControllerをpopしてalert表示する。
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func handleShowSignUp() {
        let vc = RegistrationController()
        vc.delegate = delegate  //RegistrationControllerから自分をまたいでMainTabController上で実行される為
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //viewModel側で、emailとpasswordが両方共に空でなければ色とisEnabldが変わるような仕組みを作っている。
    @objc private func textDidChange(sender: UITextField) {
        if sender == emailTextField {
            viewModel.email = sender.text
        } else {
            viewModel.password = sender.text
        }
        updateButtonState()
    }
    
    private func updateButtonState() {
        loginButton.backgroundColor = viewModel.buttonBackgroundColor
        loginButton.setTitleColor(viewModel.buttonTitleColor, for: .normal)
        loginButton.isEnabled = viewModel.formIsValid
    }
}


//MARK: - UITextFieldDelegate

extension LoginController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField{
            passwordTextField.becomeFirstResponder()
        }else{
            passwordTextField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - ResetPasswordControllerDelegate

extension LoginController: ResetPasswordControllerDelegate {  //パスワードリセットのページからのdelegateメソッド
    
    func controllerDidSendResetPasswordLink(_ controller: ResetPasswordController) {
        navigationController?.popViewController(animated: true)
        showMessage(withTitle: "Success",
                    message: "We sent a link to your email to reset your password")
    }
}
