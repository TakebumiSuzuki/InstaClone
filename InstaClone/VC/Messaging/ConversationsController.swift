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
    private var conversations = [Message]()
    private var conversationsDictionary = [String: Message]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        fetchConversations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        
        navigationItem.title = "Messages"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain,
                                                           target: self, action: #selector(handleDismissal))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self,
                                                            action: #selector(showNewMessage))
    }
    
    func showChatController(forUser user: User) {  //cellがdidSelectedの時に呼ばれる。userはパートナーのUserオブジェクト
        let controller = ChatController(user: user)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - API
    
    func fetchConversations() {  //ここのロジックはおかしい。最初のconversationsと最後のconversationsが同一になってしまっている。
        
        //messagesコレクション内の自分のdocID内のrecent-messages内のドキュメントをsnapshotListnerで時系列に取り出して[Message]にして返す
        MessagingService.fetchRecentMessages { conversations in  //conversationsの実態はtimestamp順の[Message]
            print(conversations)
            conversations.forEach { conversation in
                self.conversationsDictionary[conversation.chatPartnerId] = conversation
                //ここでは["相手のID": Messageオブジェクト]という辞書を作っている事になる。
            }
            
            self.conversations = Array(self.conversationsDictionary.values) //辞書の各値のみ取り出して配列にしている。
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @objc func showNewMessage() {  //メッセージの新規作成。searchControllerに.messageを入れてpresentしている。
        let controller = SearchController(config: .messages)
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }
    
    @objc func handleDismissal() {
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - UITableViewDataSource

extension ConversationsController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ConversationCell
        //チャットページと同じviewModelを共用しているが、こちらでは数個のプロパティのみ使用している。
        cell.viewModel = MessageViewModel(message: conversations[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ConversationsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showLoader(true)
        
        UserService.fetchUser(withUid: conversations[indexPath.row].chatPartnerId) { user in
            self.showLoader(false)
            self.showChatController(forUser: user)
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
    
    func controller(_ controller: SearchController, wantsToStartChatWith user: User) {
        dismiss(animated: true, completion: nil)
        showChatController(forUser: user)
    }
}

