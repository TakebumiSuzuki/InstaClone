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

//.messageモードでcellをタップした場合にチャットスタートするためだけに使われる。
protocol SearchControllerDelegate: class {
    func controller(_ controller: SearchController, wantsToStartChatWith user: User)
    func controller(_ controller: SearchController, wantsToShowSelectedUser user: User )
}



//このUserFilterConfigはinitの際に同時に代入される。
enum UserFilterConfig: Equatable {  //Equatableがあるとイコールが使える。条件分岐で使えるという事。
    
    case followers(String)  //profileページのfollower押した時。Stringには自分のuidが入る
    case following(String)  //profileページのfollowing押した時。Stringには自分のuidが入る
    case likes(String)  //feedページのlike押した時。StringにはpostIDが入る
    case messages(String)  //ConversationsControllerのshowNewMessageから。Stringには自分のuidが入る。
    case all  //tabからのアクセス初期画面。この時のみtableViewが隠れ、collectionViewが表示される。これ以外は全てtableViewのみ表示。
    
    var navigationItemTitle: String {  //navBar表示用
        switch self {
        case .followers: return "Followers"
        case .following: return "Following"
        case .likes: return "Likes"
        case .messages: return "New Messages" //以上4つの場合はsearchBarは表示されないし、する必要がない。
        case .all: return "Search"  //最初の画面は全ポスト表示。.messagesと.allの場合はuserは全登録者表示。
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
    
    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.alwaysBounceVertical = true
        cv.backgroundColor = .white
        cv.register(ProfileCell.self, forCellWithReuseIdentifier: postCellIdentifier)
        return cv
    }()
    
    //searchControllerがアクティブでsearchBarが空でない場合のみtrue。これにより、tableViewでusersを使うかfilteredUsersを使うか。
    //結論的には、searchBar内をタップするとtableViewでuserを表示(さらにその中でusersを使うかfilteredUsersを使うか分岐)。
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
        configureSearchController()
        configureUI()
        fetchUsers()
        if config == .all{
            fetchPosts()
        }
    }
   
   
    // MARK: - Helpers
    
    func configureSearchController() {
        if config == .all{
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
    }
    
    func configureUI() {
        view.backgroundColor = .white
        navigationItem.title = config.navigationItemTitle
        
        tableView.register(UserCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 64
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        
        view.addSubview(tableView)  //ページを開いた初期画面では、.all以外の時にはtableViewが、.allの時にはcollectionViewが表示される。
        tableView.fillSuperview()  //superViewの上下左右に貼り付けるextensionメソッド
        tableView.isHidden = config == .all  //Equatableプロトコルのおかげで等式が使える。
        
        guard config == .all else { return }
        view.addSubview(collectionView)
        collectionView.fillSuperview()
    }
    
    // MARK: - API
    
    func fetchUsers() {   //configによって内容は変わるが、全てのcaseでそれぞれ違う種類の[User]が返される。
        
        UserService.fetchUsers(forConfig: config) { users in  //エラー時はreturnされるので特にハンドリングする必要ないのでは。。
            self.users = users
            self.tableView.reloadData()
        }
    }
    
    func fetchPosts() {   //.allの時のみこれが起動。全ユーザーからの全投稿を時系列で取り出し表示する
        PostService.fetchPosts { posts in
            self.posts = posts
            self.collectionView.reloadData()
        }
    }
}

// MARK: - UISearchResultsUpdating

extension SearchController: UISearchResultsUpdating {
    
    //search機能は.allの時のみ。それ以外のモードではこのメソッドは使わない。
    //searchBarがfirstResponderになった時と、毎回文字が入力された時に呼ばれる。つまりインクリメンタルサーチができる。
    func updateSearchResults(for searchController: UISearchController) {
        
        if !inSearchMode{
            if !searchController.isActive{  //firstResponderになっていない時。つまり.allの初期画面かcancelボタンを押した直後。→Post表示。
                tableView.isHidden = true
                collectionView.isHidden = false
                collectionView.reloadData()  //viewDidLoadで予めDLした全ポスト検索のデータをリロードするだけ。
                print("POST 表示")
            }else{                          //firstResponderになっている時で、かつ文字がスペースのみ(空文字)の時。→全ユーザー表示
                tableView.isHidden = false
                collectionView.isHidden = true
                tableView.reloadData()      //viewDidLoadで予めDLした全ユーザー検索のデータをリロードするだけ。
                print("空文字の時")
            }
        }
        
        if inSearchMode{    //以下は実際に文字が打ち込まれてサーチ状態になっている時。
            
            guard let rawText = searchController.searchBar.text else { return }
            let text = rawText.trimmingCharacters(in: .whitespaces)
            
            if text.count < 2{    //ここはつまりは一文字のみが打ち込まれている場合。フルネームとユーザーネーム両方から検索
                collectionView.isHidden = true
                tableView.isHidden = false
                searchWithName(text: text.lowercased())
                print("count<2")
                return
            }
            
            if let detectedEmail = text.resolveEmails(){  //emailから検索。
                collectionView.isHidden = true
                tableView.isHidden = false
                searchWithEmail(text: detectedEmail)
                
            }else if let detectedHashtag = text.resolveHashtags(){  //ここのみAPIを使う。
                collectionView.isHidden = false
                tableView.isHidden = true
                PostService.fetchPosts(forHashtag: detectedHashtag) { (posts) in
                    self.filteredPosts = posts
                    self.collectionView.reloadData()
                }
                
            }else if let detectedMention = text.resolveMentions(){  //ユーザーネームからのみ検索
                collectionView.isHidden = true
                tableView.isHidden = false
                searchWithMention(text: detectedMention)
                
            }else{  //フルネームとユーザーネーム両方から検索
                collectionView.isHidden = true
                tableView.isHidden = false
                searchWithName(text: text.lowercased())
                print("通常のfullname & username 検索")
            }
        }
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
        
        let user = inSearchMode ? filteredUsers[indexPath.row] : users[indexPath.row]
        cell.viewModel = UserCellViewModel(user: user)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SearchController: UITableViewDelegate {
    
    //tableViewのcellをタップしたときは、.messageの場合のみチャットスタート、それ以外はProfileControllerがpushされる
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        if config == .messages(uid){  //uidは以下では使っていないが、これが正しくないと実行されない。
            delegate?.controller(self, wantsToStartChatWith: users[indexPath.row])  //ConversationsControllerがdelegate
        } else {
            let user = inSearchMode ? filteredUsers[indexPath.row] : users[indexPath.row]
            if let delegate = delegate{  //tabBar以外からの表示の場合。
                delegate.controller(self, wantsToShowSelectedUser: user)
            }else{   //tabBarからの表示の場合
                let vc = ProfileController(user: user)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
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
        vc.post = posts[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}


