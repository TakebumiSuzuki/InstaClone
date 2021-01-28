//
//  ProfileController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit

private let cellIdentifier = "ProfileCell"
private let headerIdentifier = "ProfileHeader"


//このページは様々なページへとリンクしているので複雑になる。
//画面上半分のheaderViewを表示させるため、ProfileHeaderViewModelを作り、自分がdelegateになる。
//画面半分下のポストをタップすると、その単体のポストでFeedControllerをpush。各ポストのcellに対してPostViewModelを作る。
//headerViewにはProfileHeaerVMとProfileHeaderViewが、cellにはProfileCellとPostVMが使われている。

class ProfileController: UICollectionViewController {
    
    // MARK: - Properties
    
    //userはアプリ起動時には自分のuserが入るが、使用中の経路により、他人のuserにもなりうる。また、プロパティが更新されただけでinvokeする。
    //重要な事はここでpassされているuserはstructであり、元のuser(MainTabControllerのストアプロパティ)とは別に作られたコピーであるという事。
    //そもそもUserをstructじゃなくてclassで作るべきなのでは?
    private var user: User {
        didSet { collectionView.reloadData() }  //ここにfetchUserStats()が抜けているので付け足すべき。viewDidLoad()からしか呼ばれない設計なので。
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
        checkIfUserIsFollowed()  //APIアクセスをして自分がuserをフォローしているかを調べてuserオブジェクトを更新(Boolを代入する)
        fetchUserStats()  //APIアクセスをしてuserのstatsオブジェクトを生成して、userオブジェクトに代入する。
        fetchPosts()  //APIアクセスをしてpost配列をget。以上の数行はAsync処理なので、同時進行でCollectionViewのDatasourceなどが呼ばれる。
    }
    
    
    
    // MARK: - Helpers
    
    private func configureCollectionView() {
        navigationItem.title = user.username
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
    
    @objc func handleRefresh() {
        posts.removeAll()
        fetchPosts()
    }
    
    
    // MARK: - API
    
    func checkIfUserIsFollowed() {  //中央のボタンの表示(3種類ある)がどれになるかを決定するために必要
        UserService.checkIfUserIsFollowed(uid: user.uid) { isFollowed in
            self.user.isFollowed = isFollowed
        }
    }
    
    func fetchUserStats() {  //問題はこのuserStatsをAPIからgetしてuserをアップデートするメソッドがviewDidLoad()からしか呼ばれていない事。
        UserService.fetchUserStats(uid: user.uid) { stats in
            self.user.stats = stats
            self.collectionView.reloadData()
        }
    }
    
    func fetchPosts() {  // 一つ上のfetchUserStatsとかなり被ったAPIアクセスなのでお金の無駄が生じているかと。。
        PostService.fetchPosts(forUser: user.uid) { posts in
            self.posts = posts
            self.collectionView.reloadData()
            self.collectionView.refreshControl?.endRefreshing()
        }
    }
}


// MARK: - UICollectionViewDataSource

extension ProfileController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ProfileCell
        cell.viewModel = PostViewModel(post: posts[indexPath.row])  //PostViewModelを流用している
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
                
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerIdentifier, for: indexPath) as! ProfileHeader
        header.delegate = self
        header.viewModel = ProfileHeaderViewModel(user: user)
        return header
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
        let controller = FeedController(collectionViewLayout: UICollectionViewFlowLayout())
        controller.post = posts[indexPath.row]
        navigationController?.pushViewController(controller, animated: true)
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
            UserService.unfollow(uid: user.uid) { error in
                self.user.isFollowed = false  //こうしてisFollowedプロパティが変更されるとuserのdidSetが起動する。
                
                NotificationService.deleteNotification(toUid: user.uid, type: .follow)
            }
        } else {     //フォローしていない人の写真を見ている場合→フォロー
            UserService.follow(uid: user.uid) { error in
                self.user.isFollowed = true
                
                NotificationService.uploadNotification(toUid: user.uid,
                                                       fromUser: currentUser,
                                                       type: .follow)
            }
        }
    }
    
    func header(_ profileHeader: ProfileHeader, wantsToViewFollowersFor user: User) {
        
        let controller = SearchController(config: .followers(user.uid))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func header(_ profileHeader: ProfileHeader, wantsToViewFollowingFor user: User) {
        let controller = SearchController(config: .following(user.uid))
        navigationController?.pushViewController(controller, animated: true)
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
