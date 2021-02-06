//
//  NotificationController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit

private let reuseIdentifier = "NotificationCell"


//notificationのアップロード元はlikeボタン、comment、followボタン。このうちlikeとfollowは削除可能。
class NotificationsController: UITableViewController {
    
    // MARK: - Properties
    
    private var notifications = [Notification]() {
        didSet { tableView.reloadData() }
    }
    
    let refresher = UIRefreshControl()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        fetchNotifications() //viewWillAppearに入れるべきではと。。
    }
    
    
    // MARK: - Helpers
    
    func configureTableView() {
        view.backgroundColor = .white
        navigationItem.title = "Notifications"
        
        tableView.register(NotificationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        
        refresher.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refresher
    }
    
    // MARK: - API
    
    func fetchNotifications() {
        NotificationService.fetchNotifications { result in
            switch result{
            case .failure(let error):
                self.refresher.endRefreshing()
                print("DEBUG: Error fetching notifications.\(error)")
            case .success(let notifications):
                self.notifications = notifications  //APIからの返り値である右辺のnotificationsはmutateできないのでglobal変数にここでコピーしている。
                self.checkIfUserIsFollowed()
            }
        }
    }
    
    func checkIfUserIsFollowed() {
        let group = DispatchGroup()
        
        notifications.forEach { notification in  //ここで新しく定義したnotificationはletとして扱われるのでmutateできない。
            group.enter()
            guard notification.type == .follow else { group.leave(); return }   //.follow関連のnotificationの時のみチェック。
            
            //notificationはmutateできないので以下のような作業をし、元になるnotificationsの各要素を直接書き換えている。
            UserService.checkIfUserIsFollowed(uid: notification.uid) { result in
                switch result{
                case .failure(let error):
                    group.leave()
                    print("DEBUG: Error checking if user is follwed \(error.localizedDescription)")
                case .success(let isFollowed):
                    if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
                        self.notifications[index].userIsFollowed = isFollowed
                        group.leave()
                        self.refresher.endRefreshing()
                    }else{
                        group.leave()
                    }
                }
            }
        }
        group.notify(queue: .main) {
            self.refresher.endRefreshing()
        }
    }
    
    // MARK: - Actions
    
    @objc func handleRefresh() {
        fetchNotifications()  //この処理の中でエラーハンドリングをしっかりしたので問題ないと思うが、念のために下の10秒ルールを課しておく。
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.refresher.endRefreshing()
        }
    }
}

// MARK: - UITableViewDataSource

extension NotificationsController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! NotificationCell
        cell.delegate = self
        cell.viewModel = NotificationViewModel(notification: notifications[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NotificationsController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        UserService.fetchUser(withUid: notifications[indexPath.row].uid) { (result) in
            switch result{
            case .failure(let error):
                print("DEBUG: Error fetching User: \(error.localizedDescription)")
                
            case .success(let user):
                let vc = ProfileController(user: user)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

// MARK: - NotificationCellDelegate

extension NotificationsController: NotificationCellDelegate {
    
    //followボタンを押した時。firebase上の情報を更新した後、viewModel上の情報をローカルで変更。合計3つの工程を経る必要がある。
    func cell(_ cell: NotificationCell, wantsToFollow uid: String) {
        guard let tab = tabBarController as? MainTabController else{ return }
        guard let user = tab.user else{ return }
        
        cell.viewModel?.notification.userIsFollowed.toggle()  //1.即席でUIを対応させる為のコード
        if let indexPath = tableView.indexPath(for: cell){
            notifications[indexPath.row].userIsFollowed = true //2.グローバル変数のnotificationsを変えることによりスクロール時のdequeue対応。
        }
        
        UserService.follow(uid: uid) { (result) in  //3.firestore上のデータを書き換える
            switch result{
            case .failure(let error):
//                self.showSimpleAlert(title: "Network Error.Failed to Follow", message: "Please try later again.", actionTitle: "ok")
                print("DEBUG: Error following process in Firestore. \(error.localizedDescription)")
            case .success(_):   //ここには"succeed"と書いたが入ったerrorが返ってくるが使わない。
                NotificationService.uploadNotification(toUid: uid, fromUser: user, type: .follow)
            }
        }
    }
    
    
    func cell(_ cell: NotificationCell, wantsToUnfollow uid: String) {
        
        cell.viewModel?.notification.userIsFollowed.toggle()  //1.即席でUIを対応させる為のコード
        
        if let indexPath = tableView.indexPath(for: cell){
            notifications[indexPath.row].userIsFollowed = false //2.グローバル変数のnotificationsを変えることによりスクロール時のdequeue対応。
        }
        UserService.unfollow(uid: uid){ (result) in
            switch result{
            case .failure(let error):
//                self.showSimpleAlert(title: "Network Error.Failed to unfollow", message: "Please try later again.", actionTitle: "ok")
                print("DEBUG: Error unfollowing process in Firestore. \(error.localizedDescription)")
            case .success(_):
                NotificationService.deleteNotification(toUid: uid, type: .follow)
            }
        }
    }
        
    
    func cell(_ cell: NotificationCell, wantsToViewPost postId: String) {

        PostService.fetchPost(withPostId: postId) { (result) in
            switch result{
            case .failure(let error):
                print("DEBUG: Error fetching a single Post \(error.localizedDescription)")
                
            case .success(let post):
                let vc = FeedController(collectionViewLayout: UICollectionViewFlowLayout())
                vc.post = post
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
