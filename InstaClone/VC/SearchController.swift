//
//  SearchController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit
import Firebase

private let reuseIdentifier = "UserCell"  //tableViewのcell
private let postCellIdentifier = "PostCell"  //collectionViewのcell



protocol SearchControllerDelegate: class {
    func controller(_ controller: SearchController, wantsToStartChatWith user: User)
    func controller(_ controller: SearchController, wantsToShowSelectedUser user: User )
}


//このUserFilterConfigはinitの際に同時に代入される。
enum UserFilterConfig: Equatable {  //Equatableがあるとイコールが使える。条件分岐で使える。
    
    case followers(String)  //profileページのfollower押した時。Stringには自分のuidが入る
    case following(String)  //profileページのfollowing押した時。Stringには自分のuidが入る
    case likes(String)  //feedページのlike押した時。StringにはpostIDが入る
    case messages(String)  //ConversationsControllerの右上、showNewMessageから。Stringには自分のuidが入る。
    case all  //tabからのアクセス初期画面。この時のみtableViewが隠れ、collectionViewが表示される。これ以外は全てtableViewのみ表示。
    
    var navigationItemTitle: String {  //navBar表示用
        switch self {
        case .followers: return "Followers"
        case .following: return "Following"
        case .likes: return "Likes"
        case .messages: return "Your Followings"   //以上4つの場合はsearchBarは表示されないし、する必要がない。
        case .all: return "Search Posts & People"  //最初の画面は全ポスト表示。.messagesと.allの場合はuserは全登録者表示。
        }
    }
}


class SearchController: UIViewController {
    
    // MARK: - Properties
    
    private let config: UserFilterConfig   //initの際に必ず代入される
    weak var delegate: SearchControllerDelegate?
    
    private var users = [User]()
    private var filteredUsers = [User]()
    private var posts = [Post]()  //tabをタップしての直接表示の初期画面のみで使われる
    private var filteredPosts = [Post]()
    
    private let refresherTV = UIRefreshControl()
    private let refresherCV = UIRefreshControl()
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private lazy var tableView: UITableView = {
        let tb = UITableView()
        //searchBarをresignFirstResponderする為。(delegateのdidSelectCellはこのページでは使わない。)
        tb.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tableViewTouched))
        tb.addGestureRecognizer(tap)
        
        refresherTV.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tb.refreshControl = refresherTV
        return tb
    }()
    
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.alwaysBounceVertical = true
        cv.backgroundColor = .white
        cv.register(ProfileCell.self, forCellWithReuseIdentifier: postCellIdentifier)
        
        refresherCV.addTarget(self, action: #selector(refreshCollectionView), for: .valueChanged)
        cv.refreshControl = refresherCV
        return cv
    }()
    
    //searchControllerがアクティブでsearchBarが空でない場合のみtrue。これにより、tableViewでusersを使うかfilteredUsersを使うかが決まる。
    //結論的には、searchBar内をタップするとtableViewでusersを表示(さらにその中でusersを使うかfilteredUsersを使うか分岐)。
    //cancelをタップするとactiveではなくなり、tableViewがhiddenされてポスト表示になる。
    private var inSearchMode: Bool {  //tableViewのdataSource内でこの論理結果を使ってusers/filteredUsersのスイッチをしている。
        return searchController.isActive && !searchController.searchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    
    // MARK: - Lifecycle
    
    init(config: UserFilterConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)  //詳細不明
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchUsers()
        if config == .all{
            configureSearchController()
            fetchPosts()
        }
    }
   
   
    // MARK: - Helpers
    
    private func configureUI() {
        view.backgroundColor = .white
        navigationItem.title = config.navigationItemTitle  //このnavigationItem.titleはnavigationController?.titleよりも優先される。
        tableView.register(UserCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 64
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        view.addSubview(tableView)  //ページを開いた初期画面では、.all以外の時にはtableViewが、.allの時にはcollectionViewが表示される。
        tableView.fillSuperview()  //superViewの上下左右に貼り付けるextensionメソッド
        
        guard config == .all else { return } //Equatableプロトコルのおかげで等式が使える。
        tableView.isHidden = true
        view.addSubview(collectionView)
        collectionView.fillSuperview()
    }
    
    private func configureSearchController() {
        searchController.searchResultsUpdater = self  //デリゲートの設定のようなもの。UISearchResultsUpdatingプロトコル。検索ロジック。
        searchController.searchBar.delegate = self   //ボタンの表示非表示などに対応する。UISearchBarDelegateプロトコル。
        searchController.searchBar.placeholder = "Search with hashtag, name, or email"
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.obscuresBackgroundDuringPresentation = false  //検索中に画面が暗くなって選択できないようになるので、ここはfalseで。
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController = searchController  //navigationItemに備わっているプロパティ。
        navigationItem.hidesSearchBarWhenScrolling = false //下にスクロールするとsearchBarが上に消えるかどうか。
        definesPresentationContext = true   //不明
    }
    
    
    //MARK: - Actions
    
    @objc private func tableViewTouched(){
        searchController.searchBar.resignFirstResponder()
    }
    
    @objc private func refreshTableView(){
        fetchUsers()
    }
    
    @objc private func refreshCollectionView(){
        fetchPosts()
    }
    
    
    // MARK: - API
    
    func fetchUsers() {   //configによって内容は変わるが、全てのcaseでそれぞれ違う種類の[User]が返される。
        UserService.fetchUsers(forConfig: config) { (result) in
            switch result{
            case .failure(let error):
                self.refresherTV.endRefreshing()
                print("DEBUG: Error fetch users for tableView: \(error.localizedDescription)")
                self.showSimpleAlert(title: "Couln't download users.Try again later.", message: "", actionTitle: "ok")
            case .success(let users):
                self.refresherTV.endRefreshing()
                self.users = users
                self.tableView.reloadData()
            }
        }
    }
    
    func fetchPosts() {   //.allの時のみこれが起動。全ユーザーからの全投稿を時系列で取り出し表示する
        PostService.fetchPosts { result in
            switch result{
            case .failure(let error):
                self.refresherCV.endRefreshing()
                print("DEBUG: Error fetching all posts: \(error.localizedDescription)")
                self.showSimpleAlert(title: "Couln't download posts.Try again later.", message: "", actionTitle: "ok")
            case .success(let posts):
                self.refresherCV.endRefreshing()
                self.posts = posts
                self.collectionView.reloadData()
            }
        }
    }
}

// MARK: - UISearchResultsUpdating

extension SearchController: UISearchResultsUpdating {  //search機能は.allの時のみ。それ以外のモード下ではこのメソッドは使わない。
    
    //searchBarがfirstResponderになった時と、毎回文字が入力された時に呼ばれる。つまりインクリメンタルサーチができる。
    func updateSearchResults(for searchController: UISearchController) {
        let inputText = searchController.searchBar.text
        switch SearchLogicService.searchLogicSwitcher(
            inSearchMode: inSearchMode, searchControllerIsActive: searchController.isActive, inputText: inputText){
        
        case .allPosts:
            tableView.isHidden = true
            collectionView.isHidden = false
            collectionView.reloadData()  //viewDidLoadで予めDLした全ポスト検索のデータをリロードするだけ。
            print("非アクティブ時: 全POST表示")
        case .allUsers:
            tableView.isHidden = false
            collectionView.isHidden = true
            tableView.reloadData()      //viewDidLoadで予めDLした全ユーザー検索のデータをリロードするだけ。
            print("空白文字の時:　全USER表示")
        case .fullnameUsername(let text):
            collectionView.isHidden = true
            tableView.isHidden = false
            searchWithName(text: text.lowercased())
            print("文字数が１文字のみの時、または通常名前検索モード: fullname/username両方からの検索結果")
        case .email(let detectedEmail):
            collectionView.isHidden = true
            tableView.isHidden = false
            searchWithEmail(text: detectedEmail)
            print("email検出!: email検索結果")
        case .hashtag(let detectedHashtag):
            collectionView.isHidden = false
            tableView.isHidden = true
            PostService.fetchPosts(forHashtag: detectedHashtag) { (posts) in
                self.filteredPosts = posts
                print(self.filteredPosts)
                self.collectionView.reloadData()
            }
            print("hashtag検出!: APIアクセスしたhashtag検索結果")
        case .mentions(let detectedMention):
            collectionView.isHidden = true
            tableView.isHidden = false
            searchWithMention(text: detectedMention)
            print("mention検出!: usernameからの検索結果")
        case .searchTextIsNil:
            break
        }
        
//
//        if !inSearchMode{
//            if !searchController.isActive{  //firstResponderになっていない時。つまり.allの初期画面かcancelボタンを押した直後。→Post表示。
//                tableView.isHidden = true
//                collectionView.isHidden = false
//                collectionView.reloadData()  //viewDidLoadで予めDLした全ポスト検索のデータをリロードするだけ。
//                print("非アクティブ時: 全POST表示")
//            }else{                          //firstResponderになっている時で、かつ文字がスペースのみ(空文字)の時。→全ユーザー表示
//                tableView.isHidden = false
//                collectionView.isHidden = true
//                tableView.reloadData()      //viewDidLoadで予めDLした全ユーザー検索のデータをリロードするだけ。
//                print("空白文字の時:　全USER表示")
//            }
//        }
//
//        if inSearchMode{    //以下は実際に文字が打ち込まれてサーチ状態になっている時。
//
//            guard let rawText = searchController.searchBar.text else { return }
//            let text = rawText.trimmingCharacters(in: .whitespaces)
//
//            if text.count < 2{    //ここはつまりは一文字のみが打ち込まれている場合。フルネームとユーザーネーム両方から検索
//                collectionView.isHidden = true
//                tableView.isHidden = false
//                searchWithName(text: text.lowercased())
//                print("文字数が１文字のみの時: fullname/username両方からの検索結果")
//                return
//            }
//
//            if let detectedEmail = text.resolveEmails(){  //emailから検索。
//                collectionView.isHidden = true
//                tableView.isHidden = false
//                searchWithEmail(text: detectedEmail)
//                print("email検出!: email検索結果")
//
//            }else if let detectedHashtag = text.resolveHashtags(){  //ここのみAPIを使う。
//                collectionView.isHidden = false
//                tableView.isHidden = true
//                PostService.fetchPosts(forHashtag: detectedHashtag) { (posts) in
//                    self.filteredPosts = posts
//                    print(self.filteredPosts)
//                    self.collectionView.reloadData()
//                }
//                print("hashtag検出!: APIアクセスしたhashtag検索結果")
//
//            }else if let detectedMention = text.resolveMentions(){  //ユーザーネームからのみ検索
//                collectionView.isHidden = true
//                tableView.isHidden = false
//                searchWithMention(text: detectedMention)
//                print("mention検出!: usernameからの検索結果")
//
//            }else{  //フルネームとユーザーネーム両方から検索
//                collectionView.isHidden = true
//                tableView.isHidden = false
//                searchWithName(text: text.lowercased())
//                print("全てのケース以外: fullname&username検索結果")
//            }
//        }
    }
    
    func searchWithName(text: String){    //フルネームとユーザーネーム両方から検索
        
        filteredUsers = users.filter({
            $0.username.contains(text) || $0.fullname.lowercased().contains(text)
        })
        self.tableView.reloadData()
    }
    
    func searchWithMention(text: String){   //ユーザーネームからのみ検索
        filteredUsers = users.filter({
            $0.username.contains(text)
        })
        self.tableView.reloadData()
    }
    
    func searchWithEmail(text: String){    //emailから検索。
        filteredUsers = users.filter({
            $0.email.contains(text)
        })
        self.tableView.reloadData()
    }
    
}

// MARK: - UISearchBarDelegate

extension SearchController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {  //cancelボタンが押されたら.allモードに。
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        searchBar.text = nil
        tableView.reloadData()
    }
}


// MARK: - UITableViewDataSource

extension SearchController: UITableViewDataSource {  //searchModeがtrue/falseによって、users/filteredUsersを使うが決まる
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inSearchMode ? filteredUsers.count : users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! UserCell
        cell.delegate = self   //profilePicture, name, fullnameをタップした時にprofileControllerを表示させる為。
        let user = inSearchMode ? filteredUsers[indexPath.row] : users[indexPath.row]
        cell.viewModel = UserCellViewModel(user: user)
        
        return cell
    }
}


// MARK: - UICollectionViewDataSource

extension SearchController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inSearchMode ? filteredPosts.count : posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: postCellIdentifier, for: indexPath) as! ProfileCell
        let post = inSearchMode ? filteredPosts[indexPath.row] : posts[indexPath.row]
        cell.viewModel = PostViewModel(post: post)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SearchController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
}

// MARK: - UICollectionViewDelegate

extension SearchController: UICollectionViewDelegate { //.allの時にPostタップで単体Feedページを表示する為。
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let vc = FeedController(collectionViewLayout: UICollectionViewFlowLayout())
        vc.post = inSearchMode ? filteredPosts[indexPath.row] : posts[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        print(collectionView.contentSize.height)
        print(collectionView.contentOffset.y)
//        if collectionView.contentOffset.y + view.frame.size.height - 100 > collectionView.contentSize.height{
//            fetchPosts(isFirstFetch: false)
//        }
    }
}

extension SearchController: UserCellDelegate{
    
    //tableViewのcellの中の名前や写真をタップしたときは、.messageの場合のみチャットスタート、それ以外はProfileControllerがpushされる
    func userCell(_ cell: UserCell, wantsToShowUserProfile user: User) {
        guard let indexPath = tableView.indexPath(for: cell) else{ return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        if config == .messages(currentUid){  //ConversationsControllerを起点としてchatページを。
            delegate?.controller(self, wantsToStartChatWith: users[indexPath.row])  //ConversationsControllerがdelegate
        } else {
            let user = inSearchMode ? filteredUsers[indexPath.row] : users[indexPath.row]
            if let delegate = delegate{  //tabBar以外からの表示の場合。presentしていたので、それを閉じて元となるコントローラを起点として。
                delegate.controller(self, wantsToShowSelectedUser: user)
            }else{   //tabBarからの表示の場合
                let vc = ProfileController(user: user)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    
}
