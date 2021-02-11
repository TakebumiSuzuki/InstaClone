//
//  RegistrationController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

class RegistrationController: UIViewController {
    
    // MARK: - Properties
    
    private var viewModel = RegistrationViewModel()
    private var profileImage: UIImage?
    
    //LoginControllerをまたいでMainTabControllerが代入されている。ログイン成功後の処理。
    weak var delegate: AuthenticationDelegate?  //AuthenticationDelegateプロトコルの宣言はLoginController.swfit上で行っている。
    private var activeTextField : UITextField? = nil   //キーボード持ち上げで使う
    
    private lazy var photoButton: UIButton = {
        let bn = UIButton(type: .system)
        bn.setImage(#imageLiteral(resourceName: "plus_photo"), for: .normal)
        bn.tintColor = .white
        bn.addTarget(self, action: #selector(handleProfilePhotoSelect), for: .touchUpInside)
        return bn
    }()
    
    private let emailTextField: CustomTextField = {    //設定行数を少なくするために作ったサブクラス
        let tf = CustomTextField(placeholder: "Email")
        tf.textContentType = .emailAddress
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none  //最初の文字を小文字に
        tf.returnKeyType = .next
        return tf
    }()
    
    private let passwordTextField: CustomTextField = {
        let tf = CustomTextField(placeholder: "Password")
        tf.textContentType = .password
        tf.isSecureTextEntry = true
        tf.disableAutoFill()   //iOSでStrongPasswordと出てしまうエラーを防ぐためだけのextensionを書いた。
        tf.returnKeyType = .next
        return tf
    }()
    
    private let fullnameTextField: CustomTextField = {
        let tf = CustomTextField(placeholder: "Full Name")
        tf.textContentType = .name
        tf.autocapitalizationType = .words
        tf.returnKeyType = .next
        return tf
    }()
    
    private let usernameTextField: CustomTextField = {
        let tf = CustomTextField(placeholder: "User Name (lower cased)")
        tf.textContentType = .nickname
        tf.autocapitalizationType = .none
        tf.returnKeyType = .done
        return tf
    }()
        
    private lazy var signUpButton: CustomButton = {
        let bn = CustomButton(type: .system)
        bn.setUp(title: "Sign Up")
        bn.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return bn
    }()
    
    private lazy var alreadyHaveAccountButton: UIButton = {
        let bn = UIButton(type: .system)
        bn.attributedTitle(firstPart: "Already have an account?", secondPart: "Log In")
        bn.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        return bn
    }()
    
    private let backgroundImage: UIImageView = {
       let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.image = UIImage(named: "pink2")
        return iv
    }()
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureTextFields()
        setupKeyboardNotification()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    deinit {
        print("--------------Registration Controller being DEINITIALIZED-----------------")
    }
    
    // MARK: - Helpers
    
    private func configureUI() {

//        configureGradientLayer()   //UIViewのextensionで定義しているmethod
        
        view.addSubview(backgroundImage)
        backgroundImage.fillSuperview()
        
        view.addSubview(photoButton)
        photoButton.centerX(inView: view)
        photoButton.setDimensions(height: 140, width: 140)
        photoButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        
        let stack = UIStackView(arrangedSubviews: [emailTextField, passwordTextField,
                                                   fullnameTextField, usernameTextField,
                                                   signUpButton])
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.anchor(top: photoButton.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 30)
    }
    
    
    private func configureTextFields(){
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        fullnameTextField.delegate = self
        usernameTextField.delegate = self
        
        emailTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        fullnameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        usernameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }
    
    private func setupKeyboardNotification(){   //システムが、textViewがfirstResponderになると自動的にpostするnotification
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification){
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return}
        
        if let activeTextField = activeTextField {
            let bottomOfTextField = activeTextField.convert(activeTextField.bounds, to: self.view).maxY
            let topOfKeyboard = view.frame.height - keyboardSize.height
            let difference = bottomOfTextField - topOfKeyboard + 80
            if difference > 0{
                UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .calculationModeLinear, animations: {
                    self.view.bounds.origin.y = difference
                }, completion: nil)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification){
        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .calculationModeLinear, animations: {
            self.view.bounds.origin.y = 0
        }, completion: nil)
    }
    
    
    // MARK: - Actions
    
    @objc private func handleSignUp() {  //問題点としてAuthのパスワードバリデーションは6文字以上という点だけでspace６回でも通ってしまう。
        
        do{
            let email = try ValidationService.validateEmail(email: emailTextField.text)
            let password = try ValidationService.validatePassword(password: passwordTextField.text)
            let fullname = try ValidationService.validateFullname(fullname: fullnameTextField.text)
            let username = try ValidationService.validateUsername(username: usernameTextField.text)
            let profileImage = try ValidationService.validateProfileImage(profileImage: self.profileImage)
            
            //以下のようにわざわざAuthCredentialsストラクトを別に作ってオブジェクト化する手続きをふむ必要はない。
             let credentials = AuthCredentials(email: email, password: password,
                                               fullname: fullname, username: username,
                                               profileImage: profileImage)
             createUserAccount(credentials: credentials)
            
        }catch ValidationError.invalidEmail{
            showSimpleAlert(title: "Email isn't in correct format.", message: "", actionTitle: "ok"); return
        }catch ValidationError.passwordLessThan6Charactors{
            showSimpleAlert(title: "Password needs at least 6 characters.", message: "", actionTitle: "ok"); return
        }catch ValidationError.profileImageNil{
            showSimpleAlert(title: "Please choose your profile photo.", message: "", actionTitle: "ok"); return
        }catch{
            return
        }
    }
    
    private func createUserAccount(credentials: AuthCredentials){
        //画像を保存し、Authでアカウントを作り、Firestoreにユーザー情報を登録するという3つの作業を全てこれで行う。
        showLoader(true)
        AuthService.registerUser(withCredential: credentials) { error in
            if let error = error {
                self.showLoader(false)
                print("DEBUG: Failed to register user: \(error.localizedDescription)")
                self.showSimpleAlert(title: error.localizedDescription, message: "", actionTitle: "ok")
                return
            }
            self.showLoader(false)
            self.delegate?.authenticationDidComplete()
        }
    }
    
    @objc private func handleProfilePhotoSelect() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }
    
    @objc private func handleShowLogin() {  //ログイン画面に戻る
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func textDidChange(sender: UITextField) {  //入力状況をviewModelに送って、そこでUI論理計算を行う
        if sender == emailTextField {
            viewModel.email = sender.text
        } else if sender == passwordTextField {
            viewModel.password = sender.text
        } else if sender == fullnameTextField {
            viewModel.fullname = sender.text
        } else {
            viewModel.username = sender.text
        }
        updateButtonState()  //毎回文字が打ち込まれるたびにこれが実行され、buttonの色を変えるかどうか判断する。
    }
    
    private func updateButtonState() {
        signUpButton.backgroundColor = viewModel.buttonBackgroundColor
        signUpButton.setTitleColor(viewModel.buttonTitleColor, for: .normal)
        signUpButton.isEnabled = viewModel.formIsValid
    }
}


//MARK: - UITextFieldDelegate

extension RegistrationController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {  //キーボードのnextボタンを押した時の挙動
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            fullnameTextField.becomeFirstResponder()
        } else if textField == fullnameTextField {
            usernameTextField.becomeFirstResponder()
        } else {
            usernameTextField.resignFirstResponder()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) { //キーボード持ち上げアクティブなtextField検出に使う
        activeTextField = textField
    }
    func textFieldDidEndEditing(_ textField: UITextField) {  //キーボード持ち上げアクティブなtextField検出に使う
        activeTextField = nil
    }
    
}

// MARK: - UIImagePickerControllerDelegate

extension RegistrationController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[.editedImage] as? UIImage else { print("Error getting UIImage from ImagePicker"); return }
        profileImage = selectedImage  //ここでglobal変数のprofileImageに格納するのは、サインインでAPIアクセスしてfirestorageに保存するから。
        
        photoButton.imageView?.contentMode = .scaleAspectFill
        photoButton.layer.cornerRadius = photoButton.frame.width / 2
        photoButton.clipsToBounds = true
        //UIViewにおけるclipToBoundsとCALayerにおけるmasksToBoundsはほぼ同等。上でclipToBoundsを設定しているので、これはなくても良いか。
//        plusPhotoButton.layer.masksToBounds = true
        photoButton.layer.borderColor = UIColor.white.cgColor
        photoButton.layer.borderWidth = 1
        photoButton.setImage(selectedImage.withRenderingMode(.alwaysOriginal), for: .normal)
        //塗り潰されるので.alwaysOriginalにしている。
        
        self.dismiss(animated: true, completion: nil)
    }
}
