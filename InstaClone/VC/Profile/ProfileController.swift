//
//  ProfileController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

private let cellIdentifier = "ProfileCell"
private let headerIdentifier = "ProfileHeader"


//画面上半分のheaderViewを表示させるため、ProfileHeaderViewModelを作り、自分がdelegateになる。
//画面半分下のポストをタップすると、その単体のポストでFeedControllerをpush。各ポストのcellに対してPostViewModelを作る。
//headerViewではProfileHeaerVMとProfileHeaderViewが、cellにはProfileCellとPostVMが使われている。
//問題となるのはuserが自分の時→Tabbarに組み込まれるのでviewDidLoadは一回のみ。さらにdeinitされない。
//userが他人の時→別画面からpushされるのでviewDidLoadとdeinitはその度に呼ばれる。これが論理混乱の元となる。

class ProfileController: UICollectionViewController {
    
    // MARK: - Properties
    
    //userはアプリ起動時には自分のuserが入るが、使用中の経路により、他人のuserにもなりうる
    //userをクラスにしたため、didSetはもはや作動しないので消して良いかと。
    private var user: User {
        didSet {
            collectionView.reloadData()
        }
    }
    private var posts = [Post]()
    
    
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
                self.checkIfUserIsFollowed()  //APIアクセスをして自分がuserをフォローしているかを調べてuserオブジェクトを更新(Boolを代入する)。最後でreloadData()が実行される
                self.fetchUserStats()  //APIアクセスをしてuserのstatsオブジェクトを生成して、userオブジェクトに代入する。最後でreloadData()が実行される
                self.fetchPosts()  //APIアクセスをしてpost配列をget。最後でreloadData()が実行される
            }
        }
   }
    
    deinit {
        print("profilecontroller deinited------------------------------------------------")
    }
    
    
    // MARK: - Helpers
    
    private func configureCollectionView() {
        
        collectionView.backgroundColor = .white
        collectionView.register(ProfileCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.register(ProfileHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: headerIdentifier)
        
        let refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refresher
    }
    
    private func showEditProfileController() {  //自分のEditページを開く(これが呼ばれるのは自分自身のページを見ている場合のみ)
        let vc = EditProfileController(user: user)  //このページが保持するuserをそのまま引き継がせる
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - Actions
    
    @objc func handleRefresh() {  //checkIfUserIsFollowed()をここに含める必要はない。他ユーザーからの干渉はないので。
        fetchPosts()
        fetchUserStats()
    }
    
    
    // MARK: - API
    //これらのメソッドはuserとpostsをmutateする。
    func checkIfUserIsFollowed() {  //中央のボタンの表示(3種類ある)がどれになるかを決定するために必要
        UserService.checkIfUserIsFollowed(uid: user.uid) { (result) in
            switch result{
            case .failure(let error):
                print("DEBUG: Error cheking if user is followed. \(error)")
            case .success(let isFollowed):
                self.user.isFollowed = isFollowed
                self.collectionView.reloadData()
            }
        }
    }
    
    func fetchUserStats() {
        UserService.fetchUserStats(uid: user.uid) { stats in
            self.user.stats = stats   //statsの値が変化していなくてもこのラインがある事によりuserのdidSetは必ず発動される。
            self.collectionView.reloadData()
        }
    }
    
    func fetchPosts() {  // 一つ上のfetchUserStatsとかなり被ったAPIアクセスなのでお金の無駄が生じているかと。。
        PostService.fetchPosts(forUser: user.uid) { result in
            switch result{
            case .failure(_):
                self.showSimpleAlert(title: "Error", message: "Fialed to download new posts", actionTitle: "ok")
                self.collectionView.refreshControl?.endRefreshing()
            case .success(let posts):
                self.posts = posts
                self.collectionView.reloadData()
                self.collectionView.refreshControl?.endRefreshing()
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
        cell.viewModel = PostViewModel(post: posts[indexPath.row])  //PostViewModelを流用している
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



// MARK: - ProfileHeaderDelegate

extension ProfileController: ProfileHeaderDelegate {
    
    //followするかどうか、その場合のnotificationのFirebaseへのセーブ/消去、または自分の場合プロファイル画面を表示するロジック。ちょっと複雑
    func header(_ profileHeader: ProfileHeader, didTapActionButtonFor user: User) {
        
        guard let tab = tabBarController as? MainTabController else { return }
        guard let currentUser = tab.user else { return }  //tabbarからさかのぼって自分自身のuserオブジェクトをgetしている
        
        if user.isCurrentUser {    //自分自身のプロフィール画面を見ている場合→自分のエディット画面
            showEditProfileController()
            
        } else if user.isFollowed {    //すでにフォローしている人のプロフィールを見ている場合→アンフォロー
            user.isFollowed = false
            user.stats.followers -= 1
            profileHeader.configure()  //userはクラスオブジェクトなので一番上のdidSetは機能しなくなっている。代わりにこれでok。
            UserService.unfollow(uid: user.uid) { error in
                
                NotificationService.deleteNotification(toUid: user.uid, type: .follow)
            }
            
        } else {     //フォローしていない人の写真を見ている場合→フォロー
            user.isFollowed = true
            user.stats.followers += 1
            profileHeader.configure()
            UserService.follow(uid: user.uid) { error in
                
                NotificationService.uploadNotification(toUid: user.uid,
                                                       fromUser: currentUser,
                                                       type: .follow)
            }
        }
    }
    
    func header(_ profileHeader: ProfileHeader, wantsToViewFollowersFor user: User) {
        let vc = SearchController(config: .followers(user.uid))
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
//        navigationController?.pushViewController(vc, animated: true)
    }
    
    func header(_ profileHeader: ProfileHeader, wantsToViewFollowingFor user: User) {
        let vc = SearchController(config: .following(user.uid))
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
//        navigationController?.pushViewController(vc, animated: true)
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


// MARK: - EditProfileControllerDelegate

//自分自身の情報をエディットした時にEditProfileControllerから呼ばれる。
extension ProfileController: EditProfileControllerDelegate {
    
    func controller(_ controller: EditProfileController, wantsToUpdate user: User) {
        controller.dismiss(animated: true, completion: nil)
        self.user = user  //userが更新されるとdidSetでreloadされる。
    }
}

//MARK: - SearchControllerDelegate
extension ProfileController: SearchControllerDelegate{
    func controller(_ controller: SearchController, wantsToStartChatWith user: User) {
    }
    
    func controller(_ controller: SearchController, wantsToShowSelectedUser user: User) {
        dismiss(animated: true, completion: nil)
        let vc = ProfileController(user: user)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
