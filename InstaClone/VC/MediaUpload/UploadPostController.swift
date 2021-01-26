//
//  UploadPostController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

//shareボタン押した後にmainTabController上で実行するためのプロトコル。feedタブを選択し、このVCと親navをdismissし、リロード。
protocol UploadPostControllerDelegate: class {
    func controllerDidFinishUploadingPost(_ controller: UploadPostController)
}

//真ん中のtabがタップされて写真を選択した後に、MainTabController上で、navBar内に格納されfull screenでpresentされる。
class UploadPostController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: UploadPostControllerDelegate?  //MainTabControllerが入る
        
    var selectedImage: UIImage? {  //YPImagePickerで選択されたUIImageがインスタンス化時に代入される
        didSet { photoImageView.image = selectedImage }
    }
    var currentUser: User? //ここに大きな問題がある。このuserはMainTabからパスされたコピーであり、profileでアップデートしたuserとは異なる。
    //以上の3つの変数はインスタンス化の時にMainTabControllerから代入される
    
    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private lazy var captionTextView: InputTextView = {
        let tv = InputTextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.placeholderText = "Enter caption.."
        tv.placeholderShouldCenter = false  //"Enter caption.."が左上部に表示される
        tv.delegate = self   //一番下にある、文字入力するたびに呼ばれるUITextViewDelegateを使用する為
        return tv
    }()
    
    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "0/100"
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    
    // MARK: - Helpers
    
    func configureUI() {
        
        view.backgroundColor = .white
        navigationItem.title = "Upload Post"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(didTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .done,
                                                            target: self, action: #selector(didTapDone))
        
        view.addSubview(photoImageView)
        photoImageView.setDimensions(height: 180, width: 180)
        photoImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 8)
        photoImageView.centerX(inView: view)
        photoImageView.layer.cornerRadius = 10
        
        view.addSubview(captionTextView)
        captionTextView.anchor(top: photoImageView.bottomAnchor, left: view.leftAnchor,
                               right: view.rightAnchor, paddingTop: 16, paddingLeft: 12,
                               paddingRight: 12, height: 64)
        
        view.addSubview(characterCountLabel)
        characterCountLabel.anchor(bottom: captionTextView.bottomAnchor, right: view.rightAnchor,
                                   paddingBottom: -8, paddingRight: 12)
    }
    
    
    // MARK: - Actions
    
    @objc func didTapCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapDone() {
        guard let image = selectedImage else { return }
        guard let caption = captionTextView.text else { return }
        guard let user = currentUser else { return }
        
        showLoader(true)
        
        //このメソッドの呼び出し先のImageUploaderでprofile_imageパスが使われてしまっている。機能に影響はないと思うが直すべき。
        PostService.uploadPost(caption: caption, image: image, user: user) { error in
            self.showLoader(false)

            if let error = error {
                print("DEBUG: Failed to upload post with error \(error.localizedDescription)")
                return
            }
            //ここにnotificationCenterを記述してfeedControllerがreloadできるようにし、下のdelegateはhandlerの外に出すべき。
            self.delegate?.controllerDidFinishUploadingPost(self)
        }
    }
}


// MARK: - UITextViewDelegate

extension UploadPostController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        checkMaxLength(textView)
        let count = textView.text.count
        characterCountLabel.text = "\(count)/100"
    }
    
    func checkMaxLength(_ textView: UITextView) {
        if (textView.text.count) > 100 {
            textView.deleteBackward()  //このメソッドは覚えるしかない。
        }
    }
}
