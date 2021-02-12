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
class EditProfileController: UITableViewController {
    
    // MARK: - Properties
    
    private var user: User    //インスタンス化の際にProfileControllerのuserのリファレンスがパスされる
    weak var delegate: EditProfileControllerDelegate?  //ProfileControllerが入る


    private lazy var headerView = EditProfileHeader(user: user)
    private let imagePicker = UIImagePickerController()
    
    private var selectedImage: UIImage? {   //imagePickerで選択した写真のUIImageがここに代入される
        didSet { headerView.profileImageView.image = selectedImage }
    }
    
    private var userInfoChanged = false  //SaveボタンのisEnabledを操作するため
    private var imageChanged: Bool {     //SaveボタンのisEnabledを操作するため
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
        print("---------------------EditProfileController is being DEINITIALIZED-------------------")
    }
    
    // MARK: - Helpers
    
    private func configureImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "Edit Profile"
        //下の2つはbarButtonSystemItemでも通常のtitleでもどちらもほぼ同じ。
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(handleSave))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    private func configureTableView() {
        headerView.delegate = self
        tableView.tableHeaderView = headerView
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 180)
        tableView.tableFooterView = UIView()
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
        tableView.rowHeight = 60
        tableView.register(EditProfileCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)  //セパレーターの左右inset
    }
    
    // MARK: - Selectors
    
    @objc private func hideKeyboard() {  //UITapGestureから呼ばれる
      view.endEditing(true)
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleSave() {
        view.endEditing(true)
        guard imageChanged || userInfoChanged else { return }
        updateUserData()
    }
    
    
    // MARK: - API
    
    private func updateUserData() {
        //両方の場合共に、過去のポスト、notification,commentに含まれる情報をアップデートする必要があるがまだ未実装。
        if imageChanged{
            updateProfileImageThenNames()
        }else{
            updateNames()
        }
    }
    
    private func updateProfileImageThenNames() {
        guard let image = selectedImage else { return }
        
        //古いimageバケットを消去し、新たにimageをstorageに保存し、そのDLリンクまたはエラーを返す。
        UserService.updateProfileImage(forUser: user, image: image) { profileImageUrl, error in
            if let error = error {
                self.showSimpleAlert(title: "Error", message: error.localizedDescription, actionTitle: "ok")
                return
            }
            guard let profileImageUrl = profileImageUrl else { return }
            self.user.profileImageUrl = profileImageUrl  //ローカルのuserオブジェクトに新しいimageURLを代入
            
            self.updateNames()
        }
    }
    
    private func updateNames(){
        
        //以下６行でローカルのuserオブジェクトのnameとusernameをアップデートする。
        let fullnameCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? EditProfileCell
        guard let fullname = fullnameCell?.infoTextField.text else { return }
        user.fullname = fullname
        
        let usernameCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? EditProfileCell
        guard let username = usernameCell?.infoTextField.text else { return }
        user.username = username
        
        UserService.saveUserData(user: user){ (error) in
            if let error = error {
                self.showSimpleAlert(title: "Error", message: error.localizedDescription, actionTitle: "ok")
                return
            }
            self.delegate?.controller(self, wantsToUpdate: self.user)
        }
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
        
        userInfoChanged = true
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}
