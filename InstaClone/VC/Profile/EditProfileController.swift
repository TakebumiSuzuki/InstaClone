//
//  EditProfileController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

private let reuseIdentifier = "EditProfileCell"

//このプロトコルはProfileController内で実行される。userをこのページで更新した内容にアップデートしてリロード。
protocol EditProfileControllerDelegate: class {
    func controller(_ controller: EditProfileController, wantsToUpdate user: User)
}

//ユーザーネームなど変更時にキーボードが閉まらないというバグがありtouchBeginを使っても解消できない。gestureで多分解決できる
//このページのポイントはuserオブジェクトを前ページのProfileControllerからコピーでパスされ、また逆方向にコピーでパスするという事。
//APIアクセスではfetchする事を全くせず、userオブジェクトを更新して、それをアップロードするのみ。という事。
class EditProfileController: UITableViewController {
    
    // MARK: - Properties
    
    private var user: User    //インスタンス化の際にProfileControllerのuser structの"コピー"をそのまま引き継ぐ
    weak var delegate: EditProfileControllerDelegate?

    private lazy var headerView = EditProfileHeader(user: user)
    private let imagePicker = UIImagePickerController()
    
    private var userInfoChanged = false
    
    private var selectedImage: UIImage? {   //imagePickerで選択した写真のUIImageがここに代入される
        didSet { headerView.profileImageView.image = selectedImage }
    }
    private var imageChanged: Bool {
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
    
    override func viewDidLoad() { //このページはプレゼントされるのでviewDidLoadは毎回必ず呼ばれる
        super.viewDidLoad()
        configureImagePicker()
        configureNavigationBar()
        configureTableView()
    }
    
    // MARK: - Helpers
    
    func configureImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    func configureNavigationBar() {
        navigationItem.title = "Edit Profile"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDone))
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func configureTableView() {
        
        headerView.delegate = self
        tableView.tableHeaderView = headerView
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 180)
        
        tableView.tableFooterView = UIView()
        
        tableView.rowHeight = 48
        tableView.register(EditProfileCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    // MARK: - Selectors
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleDone() {
        view.endEditing(true)
        guard imageChanged || userInfoChanged else { return }
        
        updateUserData()
    }
    
    // MARK: - API
    
    func updateUserData() {  //ifの分類の仕方が悪い。普通にif imageChanged{}してその後にif userInfoChanged{}でよいのに。
        
        //全部でimageを変更した場合と、fullName/userNameを変更した場合とで3つのケースがありifで条件分岐している。
        if imageChanged && !userInfoChanged { //imageのみ変更した場合
            updateProfileImage()
        }
        
        if userInfoChanged && !imageChanged { //テキスト情報のみ変更した場合
            showLoader(true)
            UserService.saveUserData(user: user) { _ in
                self.showLoader(false)
                self.delegate?.controller(self, wantsToUpdate: self.user)
            }
        }
        
        if userInfoChanged && imageChanged {  //imageとテキスト両方変更した場合
            showLoader(true)
            UserService.saveUserData(user: user) { _ in
                self.updateProfileImage()
            }
        }
    }
    
    func updateProfileImage() {  //UIImageをstorageに保存し、DLをuserオブジェクトに代入し、それを添付してdelegateメソッド
        guard let image = selectedImage else { return }
        showLoader(true)
        
        UserService.updateProfileImage(forUser: user, image: image) { profileImageUrl, error in
            self.showLoader(false)

            if let error = error {
                self.showMessage(withTitle: "Error", message: error.localizedDescription)
                return
            }
            
            guard let profileImageUrl = profileImageUrl else { return }
            self.user.profileImageUrl = profileImageUrl
            
            self.delegate?.controller(self, wantsToUpdate: self.user) //ここでアップデートされたuserを逆方向パス。
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
    
    func updateUserInfo(_ cell: EditProfileCell) { //cell内のTextFieldが.editingDidEndになった時に呼ばれる
        guard let viewModel = cell.viewModel else { return }
        
        userInfoChanged = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        switch viewModel.option {
        case .fullname:
            guard let fullname = cell.infoTextField.text else { return }
            user.fullname = fullname  //本来ならdoneボタンがタップされた時にこのラインを書く方が自然

        case .username:
            guard let username = cell.infoTextField.text else { return }
            user.username = username  //本来ならdoneボタンがタップされた時にこのラインを書く方が自然
        }
    }
}
