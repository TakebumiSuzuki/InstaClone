//
//  ResetPasswordController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

//LoginController上で実行されるdelegate method。emailを送りましたとのalertを表示させる。
protocol ResetPasswordControllerDelegate: class {
    func controllerDidSendResetPasswordLink(_ controller: ResetPasswordController)
}

class ResetPasswordController: UIViewController {
    
    init(email: String) {
        super.init(nibName: nil, bundle: nil)
        self.email = email
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Properties
    
    private var viewModel = ResetPasswordViewModel()
    weak var delegate: ResetPasswordControllerDelegate?  //loginControllereが批准
    var email: String?  //前ページから引き継がれる
    
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
        tf.returnKeyType = .done
        return tf
    }()
    
    private lazy var resetPasswordButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setUp(title: "Reset Password")
        button.addTarget(self, action: #selector(handleResetPassword), for: .touchUpInside)
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.addTarget(self, action: #selector(handleDismissal), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        configureUI()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    deinit {
        print("-----------------Password Controller being DEINITIALIZED----------------------")
    }
    
    // MARK: - Helpers
    
    private func configureUI() {
        
        configureGradientLayer()
        
        emailTextField.text = email //ここからの３行は前ページから引き継いだemailをそのまま表示させるため
        viewModel.email = email
        updateButtonState()
        
        emailTextField.delegate = self
        emailTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        
        view.addSubview(backButton)
        backButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 16)
        
        view.addSubview(iconImageView)
        iconImageView.centerX(inView: view)
        iconImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        iconImageView.setHeight(80)
        iconImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        let stack = UIStackView(arrangedSubviews: [emailTextField, resetPasswordButton])
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.anchor(top: iconImageView.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
    }
    
    
    // MARK: - Actions
    
    @objc private func handleResetPassword() {
        guard let email = emailTextField.text else { return }
        guard email.isValidEmail() else{
            showSimpleAlert(title: "Email isn't in correct format.", message: "", actionTitle: "ok")
            return
        }
        
        showLoader(true)
        AuthService.resetPassword(withEmail: email) { error in
            if let error = error {
                self.showLoader(false)
                self.showSimpleAlert(title: "Error", message: error.localizedDescription, actionTitle: "ok")
                return
            }
            self.delegate?.controllerDidSendResetPasswordLink(self)
        }
    }
    
    @objc private func handleDismissal() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func textDidChange(sender: UITextField) {
        if sender == emailTextField {
            viewModel.email = sender.text
        }
        updateButtonState()
    }
    
    private func updateButtonState() {
        resetPasswordButton.backgroundColor = viewModel.buttonBackgroundColor
        resetPasswordButton.setTitleColor(viewModel.buttonTitleColor, for: .normal)
        resetPasswordButton.isEnabled = viewModel.formIsValid
    }
}


//MARK: - UITextFieldDelegate
extension ResetPasswordController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
