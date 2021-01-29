//
//  EditProfileController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

private let reuseIdentifier = "EditProfileCell"

//このプロトコルはProfileController内で実行される。userを新しいimageUrl,name,full nameにアップデートしてリロード。
protocol EditProfileControllerDelegate: class {
    func controller(_ controller: EditProfileController, wantsToUpdate user: User)
}

//ユーザーネームなど変更時にキーボードが閉めるためのtouchBeginが働かなかったが、gestureで解決済。
//このページのポイントはuserオブジェクトを前ページのProfileControllerからコピーでパスされ、また逆方向にコピーでパスするという事。
class EditProfileController: UITableViewController {
    
    // MARK: - Properties
    
    private var user: User    //インスタンス化の際にProfileControllerのuser structの"コピー"をそのまま引き継ぐ
    weak var delegate: EditProfileControllerDelegate?  //ProfileControllerが入る


    private lazy var headerView = EditProfileHeader(user: user)
    private let imagePicker = UIImagePickerController()
    
    private var selectedImage: UIImage? {   //imagePickerで選択した写真のUIImageがここに代入される
        didSet { headerView.profileImageView.image = selectedImage }
    }
    
    private var userInfoChanged = false  //右上のSaveボタンのisEnabledを操作するため
    private var imageChanged: Bool {   //右上のSaveボタンのisEnabledを操作するため
        return selectedImage != nil
    }
    
    // MARK: - Lifecycle
    
    init(user: User) {
        self.user = user
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() { //このページはpresentされるのでviewDidLoadは毎回必ず呼ばれる
        super.viewDidLoad()
        configureImagePicker()
        configureNavigationBar()
        configureTableView()
    }
    deinit {
        print("EditProfileController DEINITTING--------------------------------------------")
    }
    
    // MARK: - Helpers
    
    func configureImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    func configureNavigationBar() {
        navigationItem.title = "Edit Profile"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(handleSave))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func configureTableView() {
        tableView.tableHeaderView = headerView
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 180)
        headerView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
        tableView.rowHeight = 60
        tableView.register(EditProfileCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)  //セパレーターの左右inset
    }
    
    // MARK: - Selectors
    
    @objc func hideKeyboard() {  //UITapGestureから呼ばれる
      view.endEditing(true)
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleSave() {
        view.endEditing(true)
        guard imageChanged || userInfoChanged else { return }
        updateUserData()
    }
    
    
    // MARK: - API
    
    private func updateUserData() {
        //両方の場合共に、過去のポスト、notification,commentに含まれる情報をアップデートする必要があるがまだ未実装。
        if imageChanged{
            updateProfileImageAndName()
        }else{
            updateOnlyName()
        }
    }
    
    private func updateProfileImageAndName() {
        guard let image = selectedImage else { return }
        
        //古いimageバケットを消去し、新たにimageをstorageに保存し、そのDLリンクまたはエラーを返す。
        UserService.updateProfileImage(forUser: user, image: image) { profileImageUrl, error in
            if let error = error {
                self.showSimpleAlert(title: "Error", message: error.localizedDescription, actionTitle: "ok")
                return
            }
            guard let profileImageUrl = profileImageUrl else { return }
            self.user.profileImageUrl = profileImageUrl  //ここでローカルのuserオブジェクトに新しいimageURLを代入
            
            //この段階でuserのname,fullname,imageURLは既に変更済み。ここでfirebaseに各種テキスト情報を記録
            UserService.saveUserData(user: self.user) { (error) in
                if let error = error {
                    self.showSimpleAlert(title: "Error", message: error.localizedDescription, actionTitle: "ok")
                    return
                }
            }
            self.delegate?.controller(self, wantsToUpdate: self.user)  //アップデートされたuserを逆方向パス。
        }
    }
    
    
    private func updateOnlyName(){
        UserService.saveUserData(user: user){ (error) in
            if let error = error {
                self.showSimpleAlert(title: "Error", message: error.localizedDescription, actionTitle: "ok")
                return
            }
        }
        delegate?.controller(self, wantsToUpdate: self.user)  //アップデートされたuserを逆方向パス。
   }
}



// MARK: - UITableViewDataSource

extension EditProfileController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return EditProfileOptions.allCases.count   //.fullnameと.usernameの2つ
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! EditProfileCell
        cell.delegate = self
        guard let option = EditProfileOptions(rawValue: indexPath.row) else { return cell }
        cell.viewModel = EditProfileViewModel(user: user, option: option)
        return cell
    }
}

// MARK: - EditProfileHeaderDelegate

//ヘッダーviewからのdelegateで、タップされた時にimagePickerを表示
extension EditProfileController: EditProfileHeaderDelegate {
    
    func didTapChangeProfilePhoto() {
        present(imagePicker, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension EditProfileController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage else { return }
        self.selectedImage = image
        navigationItem.rightBarButtonItem?.isEnabled = true
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - EditProfileCellDelegate

extension EditProfileController: EditProfileCellDelegate {
    
    func updateUserInfo(_ cell: EditProfileCell) { //cell内のTextFieldが.editingDidChangedになった時に呼ばれる
        guard let viewModel = cell.viewModel else { return }
        
        userInfoChanged = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        //以下は本来ならSaveボタンがタップされた時にこのラインを書く方が自然だが、そうするとそこでまたdelegate設定が必要になるので、
        //ここの段階でローカルなuserを更新してしまう事によりその手間を省いている。
        switch viewModel.option {
        case .fullname:
            guard let fullname = cell.infoTextField.text else { return }
            user.fullname = fullname
        case .username:
            guard let username = cell.infoTextField.text else { return }
            user.username = username
        }
    }
}
