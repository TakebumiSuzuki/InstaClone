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
        fetchNotifications() //viewWillAppearに入れるべきではと。
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
        NotificationService.fetchNotifications { notifications in
            //ここではなく、checkIfUserIsFollowe()の後にnotificationを代入すべき。その際にはdispatchQueueが必要になるが。。
            self.notifications = notifications  //APIからの返り値である右辺のnotificationsはmutateできないのでglobal変数にここでコピーしている。
            self.checkIfUserIsFollowed()
        }
    }
    
    func checkIfUserIsFollowed() {
        notifications.forEach { notification in  //ここで新しく定義したnotificationはletとして扱われるのでmutateできない。
            guard notification.type == .follow else { return }   //.follow関連のnotificationの時のみチェック。
            
            //notificationはmutateできないので以下のような作業をし、元になるnotificationsの各要素を直接書き換えている。
            UserService.checkIfUserIsFollowed(uid: notification.uid) { isFollowed in
                if let index = self.notifications.firstIndex(where: { $0.id == notification.id }) {
                    self.notifications[index].userIsFollowed = isFollowed
                    self.refresher.endRefreshing()
                    print("ENDEND")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc func handleRefresh() {
        fetchNotifications()  //asyncなので、次のrefresher問題あるのでは？
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.refresher.endRefreshing()
            print("refresher JUST ENDED")
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
        
        UserService.fetchUser(withUid: notifications[indexPath.row].uid) { user in

            let controller = ProfileController(user: user)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

// MARK: - NotificationCellDelegate

extension NotificationsController: NotificationCellDelegate {
    
    //followボタンを押した時、firebase上の情報を返納した後、viewModel上の情報をローカルで変更
    func cell(_ cell: NotificationCell, wantsToFollow uid: String) {
        guard let tab = tabBarController as? MainTabController else{ return }
        guard let user = tab.user else{ return }
        
        cell.viewModel?.notification.userIsFollowed.toggle()  //即席でUIを対応させる為のコード
        if let indexPath = tableView.indexPath(for: cell){
            notifications[indexPath.row].userIsFollowed = true //グローバル変数のnotificationsを変えることによりスクロール時のdequeue対応。
        }
        UserService.follow(uid: uid) { (result) in
            switch result{
            case .failure(_):
                self.showSimpleAlert(title: "Network Error.Failed to Follow", message: "Please try later again.", actionTitle: "ok")
            case .success(_):
                print("NOTIFICATION FOLLOWに成功しました")
                NotificationService.uploadNotification(toUid: uid, fromUser: user, type: .follow)
            }
        }
    }
    
    
    func cell(_ cell: NotificationCell, wantsToUnfollow uid: String) {
        
        cell.viewModel?.notification.userIsFollowed.toggle()
        if let indexPath = tableView.indexPath(for: cell){
            notifications[indexPath.row].userIsFollowed = false
        }
        UserService.unfollow(uid: uid){ (result) in
            switch result{
            case .failure(_):
                self.showSimpleAlert(title: "Network Error.Failed to unfollow", message: "Please try later again.", actionTitle: "ok")
            case .success(_):
                print("NOTIFICATION FOLLOWに成功しました")
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
