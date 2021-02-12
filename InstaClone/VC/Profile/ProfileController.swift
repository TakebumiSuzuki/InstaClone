//
//  ProfileController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

private let cellIdentifier = "ProfileCell"
private let headerIdentifier = "ProfileHeader"


//画面上半分のheaderViewではProfileHeaerVMとProfileHeaderViewが、画面下部のcellではPostVMとProfileCellが使われている。
//headerView→ProfileHeaderViewModelを作り、自分がdelegateになる。
//画面半分下のポストをタップすると、その単体のポストでFeedControllerをpush。各ポストのcellに対してPostViewModelを作る。
//問題となるのはuserが自分の時→Tabbarに組み込まれるのでviewDidLoadは一回のみ。さらにdeinitされない。一方で、userが他人の時→別画面からpushされる
//のでviewDidLoadとdeinitはその度に呼ばれる。これが論理混乱の元となっていた。が、viewWillAppear内でAPIコールする事で解決。

class ProfileController: UICollectionViewController {
    
    // MARK: - Properties
    
    //userはアプリ起動時には自分のuserが入るが、使用中の経路により、他人のuserにもなりうる
    private var user: User
    private var posts = [Post]()
    private let refresher = UIRefreshControl()
    
    // MARK: - Lifecycle
    
    init(user: User) {
        self.user = user
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        UserService.fetchUser(withUid: user.uid) { (result) in
            switch result{
            case .failure(let error):
                print("DEBUG: Error fetching User: \(error.localizedDescription)")
                
            case .success(let user):
                self.navigationItem.title = user.username
                self.checkIfUserIsFollowed()  //APIアクセスをして自分がそのuserをフォローしているかを調べてuserオブジェクトを更新。最後でreloadData()が実行される
                self.fetchUserStats()  //APIアクセスをしてuserのstatsオブジェクトを生成して、userオブジェクトに代入する。最後でreloadData()が実行される
                self.fetchPosts()  //APIアクセスをしてpost配列をget。最後でreloadData()が実行される
            }
        }
   }
    
    deinit {
        print("------------------Profilecontroller is being DEINITIALIZED--------------------")
    }
    
    
    // MARK: - Helpers
    
    private func configureCollectionView() {
        
        collectionView.backgroundColor = .white
        collectionView.register(ProfileCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.register(ProfileHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerIdentifier)
        
        refresher.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refresher
    }
    
    private func showEditProfileController() {  //自分のEditページを開く(これが呼ばれるのは自分自身のページを見ている場合のみ)
        let vc = EditProfileController(user: user)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - Actions
    
    @objc private func handleRefresh() {  //checkIfUserIsFollowed()をここに含める必要はない。mutateされることはないので。
        fetchPosts()
        fetchUserStats()
    }
    
    
    // MARK: - API
    
    //このメソッドはuserをmutateする。
    private func checkIfUserIsFollowed() {  //中央のボタンの表示(3種類ある)がどれになるかを決定するために必要
        UserService.checkIfUserIsFollowed(uid: user.uid) { (result) in
            switch result{
            case .failure(let error):
                print("DEBUG: Error cheking if user is followed: \(error.localizedDescription)")
            case .success(let isFollowed):
                self.user.isFollowed = isFollowed
                self.collectionView.reloadData()
            }
        }
    }
    
    //このメソッドはuserをmutateする。
    private func fetchUserStats() {
        UserService.fetchUserStats(uid: user.uid) { stats in  //もしエラーになった場合は数値は初期値0のままになる。
            self.user.stats = stats
            self.collectionView.reloadData()
        }
    }
    
    private func fetchPosts() {
        PostService.fetchPosts(forUser: user.uid) { result in
            switch result{
            case .failure(let error):
                self.refresher.endRefreshing()
                print("DEBUG: Error fetching posts \(error.localizedDescription)")
                self.showSimpleAlert(title: "Error", message: "Fialed to download new posts", actionTitle: "ok")
                
            case .success(let posts):
                self.refresher.endRefreshing()
                self.posts = posts
                self.collectionView.reloadData()
            }
        }
    }
}


// MARK: - UICollectionViewDataSource

extension ProfileController {
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
                
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerIdentifier, for: indexPath) as! ProfileHeader
        header.delegate = self
        header.viewModel = ProfileHeaderViewModel(user: user)
        return header
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ProfileCell
        cell.viewModel = PostViewModel(post: posts[indexPath.row])  //cellにはPostViewModelを流用している
        return cell
    }
}


// MARK: - UICollectionViewDelegateFlowLayout

extension ProfileController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 240)
    }
}


// MARK: - UICollectionViewDelegate

extension ProfileController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = FeedController(collectionViewLayout: UICollectionViewFlowLayout())
        vc.post = posts[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}


// MARK: - ProfileHeaderDelegate

extension ProfileController: ProfileHeaderDelegate {
    
    //followするかどうか、その場合のnotificationのFirebaseへのセーブ/消去、または自分の場合プロファイル画面を表示するロジック。
    func header(_ profileHeader: ProfileHeader, didTapActionButtonFor user: User) {
        
        guard let tab = tabBarController as? MainTabController else { return }
        guard let currentUser = tab.user else { return }  //tabbarからさかのぼって自分自身のuserオブジェクトをgetしている
        
        if user.isCurrentUser {    //自分自身のプロフィール画面を見ている場合→自分のエディット画面を表示
            showEditProfileController()
            
        } else if user.isFollowed {    //すでにフォローしている人のプロフィールを見ている場合→アンフォロー
            user.isFollowed = false
            user.stats.followers -= 1
            profileHeader.configure()
            
            UserService.unfollow(uid: user.uid) { (result) in
                switch result{
                case .failure(let error):
                    print("DEBUG: Error unfollowing friend: \(error.localizedDescription)")
                case .success(_):
                    NotificationService.deleteNotification(toUid: user.uid, type: .follow)
                }
            }
            
        } else {     //フォローしていない人の写真を見ている場合→フォロー
            user.isFollowed = true
            user.stats.followers += 1
            profileHeader.configure()
            
            UserService.follow(uid: user.uid) { (result) in
                switch result{
                case .failure(let error):
                    print("DEBUG: Error following friend: \(error.localizedDescription)")
                case .success(_):
                    NotificationService.uploadNotification(toUid: user.uid, fromUser: currentUser, type: .follow) { (error) in
                        if let error = error{
                            print("DEBUG: Error sending following notification in ProfileHeaderDelegate: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func header(_ profileHeader: ProfileHeader, wantsToViewFollowersFor user: User) {
        let vc = SearchController(config: .followers(user.uid))
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    func header(_ profileHeader: ProfileHeader, wantsToViewFollowingFor user: User) {
        let vc = SearchController(config: .following(user.uid))
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    func header(_ profileHeader: ProfileHeader, wantsToPresentChatWith user: User){
        
        let vc = ChatController(user: user)
        let nav = UINavigationController(rootViewController: vc)
        nav.title = "\(user.username)"
        present(nav, animated: true, completion: nil)
    }
    
}


// MARK: - EditProfileControllerDelegate

//自分自身の情報をエディットした時にEditProfileControllerから呼ばれる。
extension ProfileController: EditProfileControllerDelegate {
    
    func controller(_ controller: EditProfileController, wantsToUpdate user: User) {
        controller.dismiss(animated: true, completion: nil)
        self.user = user
        self.collectionView.reloadData()
    }
}

//MARK: - SearchControllerDelegate
extension ProfileController: SearchControllerDelegate{
    
    func controller(_ controller: SearchController, wantsToStartChatWith user: User) {
    }
    
    //follower,followingをタップしてserachControllerが表示された後、userをタップするとこの画面経由でその人のprofileControllerがpush。
    func controller(_ controller: SearchController, wantsToShowSelectedUser user: User) {
        dismiss(animated: true, completion: nil)
        let vc = ProfileController(user: user)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
