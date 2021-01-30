//
//  FeedController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit
import Firebase

private let reuseIdentifier = "Cell"


//少し複雑になっているのは、このVCを単体のポストfeedページにも共用しているから。
class FeedController: UICollectionViewController {
    
    // MARK: - Lifecycle
    
    private var posts = [Post](){   //通常のfeed画面にはこちらの変数を使う
        didSet { collectionView.reloadData() }
    }
    
    var post: Post? {    //単体のポストを表示する場合にはこちらの変数を使う。上のpostsを使う場合にはここはnilのままになる。
        didSet { collectionView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        
        if post == nil{
            fetchPosts()   //マルチポストモード
        }else{
            checkSinglePostLiked()  //単体ポストモード
        }
    }
    
    // MARK: - Helpers
    
    func configureUI() {
        //collectionViewControllerには基本のviewも付いてくるが、collectionViewの下に隠れている。背景色を.clearにするとviewが見える
        collectionView.backgroundColor = .white
        collectionView.register(FeedCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        navigationItem.title = "Feed"
        if post == nil {  //単体ポストでない場合、つまり通常のfeed画面の場合は左右上にログアウトとメッセージへのリンクが付く
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self,
                                                               action: #selector(handleLogout))
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "send2"), style: .plain, target: self,
                                                                action: #selector(showMessages))
        }
        
        let refresher = UIRefreshControl()  //refresherControlについて他の導入例を見て調べる事。UIControllのサブクラス。
        refresher.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refresher   //UIScrollViewで定義されているプロパティ
    }
    
    
    // MARK: - Actions
    
    @objc func handleLogout() {  //Authからサインアウトした後にLoginControllerを、MainTabControllerをdelegateとしてpresent
        
        let alert = UIAlertController(title: "Would you like to Log out?", message: "", preferredStyle: .alert)
        let action1 = UIAlertAction(title: "Log out", style: .default) { (action) in
            do {
                try Auth.auth().signOut()
                let vc = LoginController()
                vc.delegate = self.tabBarController as? MainTabController
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            } catch {
                print("DEBUG: Failed to sign out")
            }
        }
        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        alert.addAction(action1)
        alert.addAction(action2)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func showMessages() {   //ConversationsControllerをpush
        let vc = ConversationsController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func handleRefresh() {
        if post == nil {  //マルチポストモード
            fetchPosts()
        }else{            //単体ポストモード
            updatePost()
        }
    }
    
    
    
    // MARK: - API
    
    func fetchPosts() {
        PostService.fetchFeedPosts { result in   //自分のuidからfeed postを取得すると同時にdidLikeも代入。
            switch result{
            case .failure(let error):
                self.collectionView.refreshControl?.endRefreshing()
                print("DEBUG: Failed to fetch posts \(error)")
                self.showSimpleAlert(title: "Server error..Failed to download feed posts.", message: "", actionTitle: "ok")
                
            case .success(let posts):
                self.collectionView.refreshControl?.endRefreshing()
                if posts.isEmpty{
                    self.showSimpleAlert(title: "Search and Follow your friends to see posts!!", message: "", actionTitle: "ok")
                    return
                }
                self.posts = posts
            }
        }
    }
    
    func checkSinglePostLiked() {     //viewDidLoadから呼ばれる。
        guard let post = post else { return }
        
        PostService.checkIfUserLikedPost(post: post) { didLike in //errorの場合はデフォルトのfalseのままになる。
            self.post?.didLike = didLike
        }
    }
    
    func updatePost(){    //refresherから呼ばれる。
        guard let post = post else {return}
        
        PostService.fetchPost(withPostId: post.postId) { (result) in
            switch result{
            case .failure(_):
                print("DEBUG Error fetching single post")  //この場合にはalertを表示させる必要ないかと。
                self.collectionView.refreshControl?.endRefreshing()
            case .success(let updatedPost):
                self.post = updatedPost
                PostService.checkIfUserLikedPost(post: post) { didLike in  //とりあえずここはエラーハンドリングなしで。
                    self.post?.didLike = didLike
                    self.collectionView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    func deletePost(_ post: Post) {  //簡単に見えて超複雑。オプションボタンからのalertで選択可能。
        self.showLoader(true)
        
        PostService.deletePost(post.postId) { _ in
            self.showLoader(false)
            self.handleRefresh()
        }
    }
}


// MARK: - UICollectionViewDataSource

extension FeedController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return post == nil ? posts.count : 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FeedCell
        cell.delegate = self
        
        handleHashtagTapped(forCell: cell)
        handleMentionTapped(forCell: cell)
        handleURLTapped(forCell: cell)
        //このページ一番下のメソッド。各cell内のcaptionLabelにhashtag、mentionをタップした時の動作をattachする。hashtagをタップすると
        //HashtagPostControllerがpushされる。このタイミングで(cell上ではなくこのFeedController上で)この作業をする事により、delegateを作る手間を省ける。
        
        if let post = post {
            cell.viewModel = PostViewModel(post: post)
        } else {
            cell.viewModel = PostViewModel(post: posts[indexPath.row])
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FeedController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = view.frame.width
        var height = width + 8 + 40 + 8
        height += 50
        height += 60
        
        return CGSize(width: width, height: height)
    }
}

// MARK: - FeedCellDelegate

extension FeedController: FeedCellDelegate {
    
    //プロフィール表示。
    func cell(_ cell: FeedCell, wantsToShowProfileFor uid: String) {
        
        UserService.fetchUser(withUid: uid) { user in  //特にエラーハンドリングの必要ないかと。
            let vc = ProfileController(user: user)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    //オプションボタン。自分のポストか他人のポストかによって表示を変えている
    func cell(_ cell: FeedCell, wantsToShowOptionsForPost post: Post) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
//        let editPostAction = UIAlertAction(title: "Edit Post", style: .default) { _ in //自分の投稿の場合
//            //エディット画面のimplementationが抜けている。
//            print("DEBUG: Edit post")
//        }
        let deletePostAction = UIAlertAction(title: "Delete Post", style: .destructive) { _ in //自分の投稿の場合
            self.deletePost(post)
        }
        let unfollowAction = UIAlertAction(title: "Unfollow \(post.ownerUsername)?", style: .default) { _ in
            self.showLoader(true)
            UserService.unfollow(uid: post.ownerUid) { _ in
                self.showLoader(false)
            }
        }
        let followAction = UIAlertAction(title: "Follow \(post.ownerUsername)?", style: .default) { _ in
            self.showLoader(true)
            UserService.follow(uid: post.ownerUid) { _ in
                self.showLoader(false)
            }
        }
        let cancelAction =  UIAlertAction(title: "Cancel", style: .cancel, handler: nil)  //キャンセルはどの場合でも表示される
        
        
        if post.ownerUid == Auth.auth().currentUser?.uid { //自分のポストにはeditとdeleteとcancel
//            alert.addAction(editPostAction)
            alert.addAction(deletePostAction)
        } else {   //自分のポストでない場合にはさらにfollowしているかしていないかでunfollow/followを変える。
            UserService.checkIfUserIsFollowed(uid: post.ownerUid) { isFollowed in
                if isFollowed {
                    alert.addAction(unfollowAction)
                } else {
                    alert.addAction(followAction)
                }
            }
        }
        
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func cell(_ cell: FeedCell, didLike post: Post) {  //postの引数は使っていないのでなくしてもよし。
        
        guard let tab = tabBarController as? MainTabController else { return }
        guard let user = tab.user else { return }
        
        guard let cellRowNumber = collectionView.indexPath(for: cell)?.row else { return }
        let ownerUid = posts[cellRowNumber].ownerUid
        
        if posts[cellRowNumber].didLike {
            posts[cellRowNumber].likes -= 1
            posts[cellRowNumber].didLike = false
            PostService.unlikePost(post: posts[cellRowNumber]) { _ in  //APIアクセスで3箇所変更(カウンター、post内のuser-likes, user内のpost-likes)
                NotificationService.deleteNotification(toUid: ownerUid, type: .like,
                                                       postId: self.posts[cellRowNumber].postId)
            }
        } else {
            posts[cellRowNumber].likes += 1
            posts[cellRowNumber].didLike = true
            PostService.likePost(post: posts[cellRowNumber]) { _ in  //APIアクセスで3箇所変更(カウンター、post内のuser-likes, user内のpost-likes)
                NotificationService.uploadNotification(toUid: ownerUid, fromUser: user,
                                                       type: .like, post: self.posts[cellRowNumber])
            }
        }
    }
    
    
    func cell(_ cell: FeedCell, wantsToShowCommentsFor post: Post) {
        let vc = CommentController(post: post)
        navigationController?.pushViewController(vc, animated: true)
    }

    
    func cell(_ cell: FeedCell, wantsToViewLikesFor postId: String) {
        let vc = SearchController(config: .likes(postId))
        navigationController?.pushViewController(vc, animated: true)
    }
}


// MARK: - ActiveLabelHandlers

extension FeedController {
    
    func handleHashtagTapped(forCell cell: FeedCell) {
        
        cell.captionLabel.handleHashtagTap { hashtag in
            let vc = HashtagPostsController(hashtag: hashtag.lowercased())
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func handleMentionTapped(forCell cell: FeedCell) {
        
        cell.captionLabel.handleMentionTap { username in
            self.showLoader(true)
            UserService.fetchUser(withUsername: username) { user in
                self.showLoader(false)
                
                if let user = user {
                    let vc = ProfileController(user: user)
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    self.showMessage(withTitle: "Error", message: "User does not exist")
                }
            }
        }
    }
    
    func handleURLTapped(forCell cell: FeedCell) {
        
        cell.captionLabel.handleURLTap { (url) in
            print("URL Tapped")
        }
    }
    
}
