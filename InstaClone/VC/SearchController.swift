//
//  SearchController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//


import UIKit

private let reuseIdentifier = "UserCell"  //tableViewのcell
private let postCellIdentifier = "PostCell"  //collectionViewのcell


//このUserFilterConfigはinitの際に同時に代入される。ポイントはfetchUserするときに、何をサーチするのかを決めるという事。
enum UserFilterConfig: Equatable {
    
    case followers(String)  //profileページのfollwer押した時。Stringにはuidが入る
    case following(String)  //profileページのfollowing押した時。Stringにはuidが入る
    case likes(String)  //feedページのlike押した時。StringにはpostIDが入る
    case messages  //ConversationsControllerから何も引数なしで遷移される
    case all  //tabからのアクセス初期画面。この時のみtableViewが隠れ、collectionViewが表示される。これ以外は全てtableViewのみ表示。
    
    var navigationItemTitle: String {  //navBar表示用
        switch self {
        case .followers: return "Followers"
        case .following: return "Following"
        case .likes: return "Likes"
        case .messages: return "New Message" //以上4つの場合はsearchBarは表示されない。
        case .all: return "Search"  //最初の画面は全ポスト表示。.messageと.allの場合はuserは全登録者表示。
        }
    }
}

//.messageモードでcellをタップした場合にチャットスタートするために使われる。
protocol SearchControllerDelegate: class {
    func controller(_ controller: SearchController, wantsToStartChatWith user: User)
}


class SearchController: UIViewController {
    
    // MARK: - Properties
    
    private let config: UserFilterConfig   //initの際に必ず代入される
    weak var delegate: SearchControllerDelegate?
    
    private var users = [User]()
    private var filteredUsers = [User]()
    private var posts = [Post]()  //tabをタップしての直接表示の初期画面で使われる
    
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
    private var inSearchMode: Bool {  //tableViewのdataSource内でこの論理結果を使ってスイッチしている。
        return searchController.isActive && !searchController.searchBar.text!.isEmpty
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
        fetchPosts()
    }
   
   
    // MARK: - Helpers
    
    func configureSearchController() {
        searchController.searchResultsUpdater = self  //デリゲートの設定のようなもの。UISearchResultsUpdatingプロトコル。検索ロジック。
        searchController.searchBar.delegate = self   //ボタンの表示非表示などに対応する。UISearchBarDelegateプロトコル。
        searchController.searchBar.placeholder = "Search"
        searchController.obscuresBackgroundDuringPresentation = false  //検索中に画面が暗くなって選択できないようになるので、ここはfalseで。
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController = searchController  //navItemに備わっているプロパティ。
        navigationItem.hidesSearchBarWhenScrolling = false //下にスクロールするとsearchBarが上に消えるかどうか。自分で書いたコード。
        definesPresentationContext = true   //不明
    }
    
    func configureUI() {
        
        view.backgroundColor = .white
        navigationItem.title = config.navigationItemTitle
        
        tableView.register(UserCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 64
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)  //ページを開いた初期画面では、.all以外の時にはtableViewが、.allの時にはcollectionViewが表示される。
        tableView.fillSuperview()  //superViewの上下左右に貼り付けるextensionメソッド
        tableView.isHidden = config == .all
        
        guard config == .all else { return }
        view.addSubview(collectionView)
        collectionView.fillSuperview()
    }
    
    // MARK: - API
    
    func fetchUsers() {   //configによって内容は変わるが、全てのcaseでusers: [User]が返される。
        UserService.fetchUsers(forConfig: config) { users in
            self.users = users
            self.tableView.reloadData()
        }
    }
    
    func fetchPosts() {   //前ユーザーからの全投稿を時系列で取り出し表示する
        PostService.fetchPosts { posts in
            self.posts = posts
            self.collectionView.reloadData()
        }
    }
}

// MARK: - UISearchResultsUpdating

extension SearchController: UISearchResultsUpdating {
    
    //searchBarがfirstResponderになった時と、毎回文字が入力された時に呼ばれる。つまりインクリメンタルサーチができる。
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        
        filteredUsers = users.filter({
            $0.username.contains(searchText) || $0.fullname.lowercased().contains(searchText)
        })
        
        self.tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate

extension SearchController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        searchBar.showsCancelButton = true
        guard config == .all else { return }  //この一行はなくても良いかと。全てのケースで同じ結果になるので。
        collectionView.isHidden = true
        tableView.isHidden = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {  //cancelボタンが押されたら.allモードに。
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        searchBar.text = nil
        
        tableView.reloadData()
        
        guard config == .all else { return }
        collectionView.isHidden = false
        tableView.isHidden = true
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
        
        if config == .messages {
            delegate?.controller(self, wantsToStartChatWith: users[indexPath.row])  //ConversationsControllerがdelegate
        } else {
            let user = inSearchMode ? filteredUsers[indexPath.row] : users[indexPath.row]
            let controller = ProfileController(user: user)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}



// MARK: - UICollectionViewDataSource

extension SearchController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: postCellIdentifier, for: indexPath) as! ProfileCell
        cell.viewModel = PostViewModel(post: posts[indexPath.row])
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

extension SearchController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controller = FeedController(collectionViewLayout: UICollectionViewFlowLayout())
        controller.post = posts[indexPath.row]
        navigationController?.pushViewController(controller, animated: true)
    }
}


