//
//  EditProfileCell.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

protocol EditProfileCellDelegate: class {
    func updateUserInfo(_ cell: EditProfileCell)  //textFieldのaddTargetからinvokeされる。
}

class EditProfileCell: UITableViewCell {
    
    // MARK: - Properties
    
    var viewModel: EditProfileViewModel? { //cell生成時にuserとoption(Enumの0または1)が代入されてviewModelが作られる。
        didSet { configure() }
    }
    
    weak var delegate: EditProfileCellDelegate?   //EditProfileControllerが入る。
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    lazy var infoTextField: UITextField = {
        let tf = UITextField()
        tf.keyboardAppearance = .default
        tf.returnKeyType = .done
        tf.autocorrectionType = .no
        tf.font = UIFont.systemFont(ofSize: 16)
        //addTargetはUIControlクラスのメソッド。AppleDocumentのUIControll>UIControl.Eventに長いリストがあるのでチェック。
        tf.addTarget(self, action: #selector(handleUpdateUserInfo), for: .editingChanged)
        return tf
    }()
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none    //cell上をタップした時に灰色の選択色にならないように。
        infoTextField.delegate = self  //一番下の、textFieldSholdReturnの為。
        
        contentView.addSubview(titleLabel)   //self.addSubviewと下のcontentView.addSubviewの違いを調べるべき
        titleLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        titleLabel.centerY(inView: self, leftAnchor: self.leftAnchor, paddingLeft: 30)
        
        contentView.addSubview(infoTextField)
        infoTextField.centerY(inView: self, leftAnchor: titleLabel.rightAnchor, paddingLeft: 16)
        //ここのpaddingLeftの部分は、上でwidthAnchorが100にセットされているので、その幅分プラス16となる。
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    func configure() {
        guard let viewModel = viewModel else { return }
        
        titleLabel.text = viewModel.titleText
        infoTextField.text = viewModel.optionValue
        //フルネームの行のみ頭文字を大文字にする為の設定
        infoTextField.autocapitalizationType = viewModel.option == .fullname ? .words : .none
    }
    
    // MARK: - Selectors
    
    @objc func handleUpdateUserInfo() {  //TextFieldが.editingDidEndになった時に呼ばれる
        delegate?.updateUserInfo(self)   //selfとはcell自身。この引数が必要な理由は実行先でcell.viewModelが必要だから
    }
    
}

//MARK: - UITextFieldDelegate
extension EditProfileCell: UITextFieldDelegate{  //キーボードのリターンキーを押した時にキーボードが閉じるように。
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
