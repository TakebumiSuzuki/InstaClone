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
    
    private var posts = [Post]() {   //通常のfeed画面にはこちらの変数を使う
        didSet { collectionView.reloadData() }
    }
    
    var post: Post? {    //単体のポストを表示する場合にはこちらの変数を使う。上のpostsを使う場合にはここはnilのままになる。
        didSet { collectionView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        fetchPosts()   //単体ポスト表示の場合はここはすぐにreturnされ実行されない
        
        if post != nil {    //単体ポスト表示の場合はこれが実行される
            checkIfUserLikedPosts()
        }
        //いずれにしろ、どのケースでも各postには必ずdidLikeが代入される。そしてdidSetでreloadData()
    }
    
    // MARK: - Helpers
    
    func configureUI() {
        //collectionViewControllerには基本のviewも付いてくるが、collectionViewの下に隠れている。背景色を.clearにするとviewが見える
        collectionView.backgroundColor = .white
        collectionView.register(FeedCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        if post == nil {  //単体ポストでない場合、つまり通常のfeed画面の場合は左右上にログアウトとメッセージへのリンクが付く
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout",style: .plain,target: self,
                                                               action: #selector(handleLogout))
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "send2"), style: .plain, target: self,
                                                                action: #selector(showMessages))
        }
        navigationItem.title = "Feed"
        
        let refresher = UIRefreshControl()  //refresherControlについて他の導入例を見て調べる事。UIControllのサブクラス。
        refresher.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refresher   //UIScrollViewで定義されているプロパティ
    }
    
    
    // MARK: - Actions
    
    @objc func handleLogout() {  //Authからサインアウトした後にLoginControllerを、MainTabControllerをdelegateとしてpresent
        do {
            try Auth.auth().signOut()
            let controller = LoginController()
            controller.delegate = self.tabBarController as? MainTabController
            let nav = UINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        } catch {
            print("DEBUG: Failed to sign out")
        }
    }
    
    @objc func showMessages() {   //ConversationsControllerをpush
        let controller = ConversationsController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc func handleRefresh() {  //単体ポストの時にもrefresherが起動する仕様になってしまっているので、バグを生むかと。
        posts.removeAll()
        fetchPosts()
    }
    
    
    // MARK: - API
    
    func fetchPosts() {
        guard post == nil else { return }   //postがnilでない場合、つまり単体ポストの場合には実行されない
        
        //user collection下の各userドキュメントにuser-feedというサブcollectionを作り、そこにdocumentIDのみの空ドキュメントを格納している。
        PostService.fetchFeedPosts { posts in
            self.posts = posts
            self.checkIfUserLikedPosts()
            self.collectionView.refreshControl?.endRefreshing()
        }
    }
    
    func checkIfUserLikedPosts() {
        if let post = post {      //単体ポストの場合には上のfetchPosts()は実行されず、スキップしてこれが実行される
            PostService.checkIfUserLikedPost(post: post) { didLike in
                self.post?.didLike = didLike
            }
        } else {   //通常のfeedページの場合。
            posts.forEach { post in  //for n in 0..<post.count{}の構文を使えばnをindex numberにできるので下のfirstIndexを使わなくても良いかと。
                PostService.checkIfUserLikedPost(post: post) { didLike in
                    if let index = self.posts.firstIndex(where: { $0.postId == post.postId }) { //$0はオリジナルのposts配列の各要素を表す。
                        self.posts[index].didLike = didLike
                    }
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
        
        handleHashtagTapped(forCell: cell)  //このページ一番下のメソッド。各cell内のcaptionLabelにhashtag、mentionをタップした時の
        handleMentionTapped(forCell: cell)  //動作をattachする。hashitagをタップするとHashtagPostControllerがpushされる。
        //このタイミングで(cell上ではなくこのFeedController上で)この作業をする事により、delegateを作る手間を省ける。
        
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
    
    func cell(_ cell: FeedCell, wantsToShowProfileFor uid: String) {
        
        UserService.fetchUser(withUid: uid) { user in
            let controller = ProfileController(user: user)
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    //オプションボタンが押された時のdelegateメソッド。自分のポストか他人のポストかによって表示を変えている
    func cell(_ cell: FeedCell, wantsToShowOptionsForPost post: Post) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let editPostAction = UIAlertAction(title: "Edit Post", style: .default) { _ in //自分の投稿の場合
            //エディット画面のimplementationが抜けている。
            print("DEBUG: Edit post")
        }
        
        let deletePostAction = UIAlertAction(title: "Delete Post", style: .destructive) { _ in //自分の投稿の場合
            self.deletePost(post)
        }
        
        let unfollowAction = UIAlertAction(title: "Unfollow", style: .default) { _ in
            self.showLoader(true)
            UserService.unfollow(uid: post.ownerUid) { _ in
                self.showLoader(false)
            }
        }
        
        let followAction = UIAlertAction(title: "Follow", style: .default) { _ in
            self.showLoader(true)
            UserService.follow(uid: post.ownerUid) { _ in
                self.showLoader(false)
            }
        }
        
        let cancelAction =  UIAlertAction(title: "Cancel", style: .cancel, handler: nil)  //キャンセルはどの場合でも表示される
        
        if post.ownerUid == Auth.auth().currentUser?.uid { //自分のポストにはeditとdelete
            alert.addAction(editPostAction)
            alert.addAction(deletePostAction)
        } else {   //自分のポストでない場合にはfollowしているかしていないかでunfollow/followを変える。
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
    
    func cell(_ cell: FeedCell, didLike post: Post) {
        
        guard let tab = tabBarController as? MainTabController else { return }
        guard let user = tab.user else { return }
        guard let ownerUid = cell.viewModel?.post.ownerUid else { return }
        
        //ここで注意すべきは、引数のpostはcell.viewModel?.postとは別の、コピーされたオブジェクトである事。letとして扱われ、immutable。
        //PostServiceのところの引数でpostを使っているが、実はこのブロック全体を通してpostの引数は必要なく、全てcell.viewModel?.postで問題ない。
        cell.viewModel?.post.didLike.toggle()  //これによりcellのconfigure()がinvokeされハート表示が自動的に更新される。
        //ちなみに引数として持ち込まれたもの(ここではpost)は通常値渡しで、尚且つletとして扱われる。参照渡しなど、関連事項検索の事。
        if post.didLike {
            PostService.unlikePost(post: post) { _ in  //APIアクセスで3箇所変更(カウンター、post内のuser-likes, user内のpost-likes)
                cell.likeButton.setImage(#imageLiteral(resourceName: "like_unselected"), for: .normal)  //ここからの２行は実は必要ない。上のtoggleで自動更新されるから。
                cell.likeButton.tintColor = .black
                cell.viewModel?.post.likes = post.likes - 1 //この行はPostServiecのすぐ上に置いた方がresponsive
                
                NotificationService.deleteNotification(toUid: ownerUid, type: .like,
                                                       postId: cell.viewModel?.post.postId)
            }
        } else {
            PostService.likePost(post: post) { _ in  //APIアクセスで3箇所変更(カウンター、post内のuser-likes, user内のpost-likes)
                cell.likeButton.setImage(#imageLiteral(resourceName: "like_selected"), for: .normal)  //ここからの２行は実は必要ない。上のtoggleで自動更新されるから。
                cell.likeButton.tintColor = .red
                cell.viewModel?.post.likes = post.likes + 1 //この行はPostServiecのすぐ上に置いた方がresponsive
                
                NotificationService.uploadNotification(toUid: post.ownerUid, fromUser: user,
                                                       type: .like, post: post)
            }
        }
    }
    
    func cell(_ cell: FeedCell, wantsToShowCommentsFor post: Post) {
        
        let controller = CommentController(post: post)
        navigationController?.pushViewController(controller, animated: true)
    }

    
    func cell(_ cell: FeedCell, wantsToViewLikesFor postId: String) {
        let controller = SearchController(config: .likes(postId))
        navigationController?.pushViewController(controller, animated: true)
    }
}


// MARK: - ActiveLabelHandlers

extension FeedController {
    
    func handleHashtagTapped(forCell cell: FeedCell) {
        
        cell.captionLabel.handleHashtagTap { hashtag in
            let controller = HashtagPostsController(hashtag: hashtag.lowercased())
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    func handleMentionTapped(forCell cell: FeedCell) {
        
        cell.captionLabel.handleMentionTap { username in
            self.showLoader(true)
            UserService.fetchUser(withUsername: username) { user in
                self.showLoader(false)
                
                if let user = user {
                    let controller = ProfileController(user: user)
                    self.navigationController?.pushViewController(controller, animated: true)
                } else {
                    self.showMessage(withTitle: "Error", message: "User does not exist")
                }
            }
        }
    }
}
