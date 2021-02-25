//
//  ConversationsController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit
import Firebase

private let reuseIdentifier = "ConversationCell"

class ConversationsController: UIViewController {
    
    // MARK: - Properties
    
    private let tableView = UITableView()
    private var messages = [Message]()
    private var conversationsDictionary = [String: Message]()
    private let messagingService = MessagingService()
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textColor = .systemGray
        label.text = "There is no conversations yet."
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchConversations()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    
    // MARK: - Helpers
    
    func configureTableView() {
        
        view.backgroundColor = .white
        tableView.backgroundColor = .white
        tableView.rowHeight = 80
        tableView.register(ConversationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        tableView.frame = view.frame
        
        view.addSubview(noConversationLabel)
        noConversationLabel.center(inView: tableView)
        
        navigationItem.title = "Messages"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain,
                                                           target: self, action: #selector(handleDismissal))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self,
                                                            action: #selector(showNewMessage))
    }
    
    func showChatController(forUser user: User) {  //cellがdidSelectedの時または新規作成ページからのdelegateで呼ばれる。
        let vc = ChatController(user: user)  //userはパートナーのUserオブジェクト
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - API
    
    func fetchConversations() {  //listener使用
        messagingService.fetchRecentMessages { (messages) in
            self.messages = messages
            self.tableView.reloadData()
            if messages.isEmpty == true{
                self.noConversationLabel.isHidden = false
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func showNewMessage() {     //メッセージの新規作成。searchControllerに.messageを入れてpresentしている。
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let vc = SearchController(config: .messages(uid))
        vc.delegate = self
        vc.fetchUsers()  //遷移先の情報を先行でロードする
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    @objc func handleDismissal() {
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - UITableViewDataSource

extension ConversationsController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ConversationCell
        //チャットページと同じviewModelを共用しているが、こちらでは数個のプロパティのみ使用している。
        cell.viewModel = MessageViewModel(message: messages[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ConversationsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showLoader(true)
        
        UserService.fetchUser(withUid: messages[indexPath.row].chatPartnerId) { (result) in
            switch result{
            case .failure(let error):
                self.showLoader(false)
                print("Error fetching User: \(error.localizedDescription)")
                
            case .success(let user):
                self.showLoader(false)
                self.showChatController(forUser: user)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }
}

// MARK: - NewMessageControllerDelegate

extension ConversationsController: SearchControllerDelegate { //SearchControllerから呼ばれる。
    
    func controller(_ controller: SearchController, wantsToShowSelectedUser user: User) {
    }
    
    //presentされている新規作成ページで誰か選んだ時に、そのページをdismissしてchatページをpushする。
    func controller(_ controller: SearchController, wantsToStartChatWith user: User) {
        dismiss(animated: true, completion: nil)
        showChatController(forUser: user)
    }
}



