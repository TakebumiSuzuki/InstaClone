//
//  ChatController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

private let reuseIdentifier = "MessageCell"

class ChatController: UICollectionViewController {
    
    // MARK: - Properties
    let messagingService = MessagingService()
    private let user: User    //会話相手のUserオブジェクト。インスタンス化時に代入される
    
    private var messages = [Message]()
    private var fromCurrentUser = false
    
    private lazy var customInputView: CustomInputAccesoryView = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let iv = CustomInputAccesoryView(config: .messages, frame: frame)
        iv.delegate = self
        return iv
    }()
    
    
    // MARK: - Lifecycle
     
    init(user: User) {
        self.user = user
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        fetchMessages()
    }
    override func viewWillDisappear(_ animated: Bool) {
        messagingService.chatListener.remove()
    }
    override var inputAccessoryView: UIView? {
        return customInputView
    }
    override var canBecomeFirstResponder: Bool {
        return true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Helpers
    
    func configureUI() {
        collectionView.backgroundColor = .white
        navigationItem.title = user.username
        collectionView.register(MessageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
    }
    
    // MARK: - API
    
    func fetchMessages() {     //Listenerを使用
        messagingService.fetchMessages(forUser: user) { (messages) in
            self.messages = messages
            self.collectionView.reloadData()
            self.collectionView.scrollToItem(at: [0, self.messages.count - 1], at: .bottom, animated: true)
        }
    }
}

//MARK: - CollectionViewDataSource

extension ChatController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MessageCell
        cell.viewModel = MessageViewModel(message: messages[indexPath.row])
        if indexPath.row % 3 != 0{
            cell.dateCellHeader.removeFromSuperview()
        }
        
        return cell
    }
    
}

extension ChatController: UICollectionViewDelegateFlowLayout {
    
    //reloadData()の度に一回だけ呼ばれる
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 16, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
    
    //各cell生成の際にindexPathごとに(つまり毎回)呼ばれる。widthはviewのwithそのまま、heightのみ算出している。このやり方は覚えるのが良いかと。
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let estimatedSizeCell = MessageCell(frame: frame)  //let estimatedSizeCellはclassなのでreference,よって下でviewModelを代入できる。
        estimatedSizeCell.viewModel = MessageViewModel(message: messages[indexPath.row])
        //上でcellを現実のデータを元に作った後で、下のlayoutIfNeeded()(UIViewのmethod)で内部レイアウトも済ませる。
        estimatedSizeCell.layoutIfNeeded()
        
        let targetSize = CGSize(width: view.frame.width, height: 1000)
        let estimatedSize = estimatedSizeCell.systemLayoutSizeFitting(targetSize)
        
        return .init(width: view.frame.width, height: estimatedSize.height)
    }
}

extension ChatController: CustomInputAccesoryViewDelegate {
    
    func inputView(_ inputView: CustomInputAccesoryView, wantsToUploadText text: String) {
        
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return }
        inputView.clearInputText()
        
        MessagingService.uploadMessage(text, to: user) { error in
            if let error = error { print("DEBUG: Failed to upload message with error: \(error.localizedDescription)"); return }
        }
    }
}

class dateHeaderView: UICollectionReusableView {    //送信日を表記するためのheaderView
    
    override init(frame: CGRect) {
            super.init(frame: frame)
//            self.backgroundColor = UIColor.red
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    
}

