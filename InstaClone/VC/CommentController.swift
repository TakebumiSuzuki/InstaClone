//
//  CommentController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

//このページのVCがdeinitされない→解決!!ActiveLabelのクロージャーが原因だった。
//reloadData()やscrollToItemを実行する時には必ずしもdispatchQueue.main.asyncの中で行う必要があるのか。
//commentInputView.commentTextViewと指定してresignFirstResponder()したらキーボードを閉じれた。


import UIKit
import ActiveLabel
import SafariServices

private let reuseIdentifier = "CommentCell"

class CommentController: UIViewController {
    
    // MARK: - Properties
    
    private let post: Post
    var postViewModel: PostViewModel?  //Feedページと同じVMを使う。画面遷移の際にFeedから渡してもらう。
    var image: UIImage?
    var caption: String?  //以上4つはinit時に代入される
    
    let commentService = CommentService()  //Listenerをremoveできるようにする為。
    private var comments = [Comment]()
    
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 6
        return iv
    }()
    
    private let captionLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .black
        label.numberOfLines = 0  //ここがfeedページの二行固定のlabelとは違うところ。
        return label
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        
        cv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(collectionViewTapped))
        cv.addGestureRecognizer(tap)
        return cv
    }()
    
    private lazy var commentInputView: CustomInputAccesoryView = {  //layz varにしている理由はwidthでviewを使っているから。
        
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let inputView = CustomInputAccesoryView(config: .comments, frame: frame)
        inputView.delegate = self
        return inputView
    }()
    
    // MARK: - Lifecycle
    
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCaptionLabel()
        configureCollectionView()
        configureUI()
    }
    
    override var inputAccessoryView: UIView? {
        get { return commentInputView }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchComments()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        commentService.commentListener.remove()  //このラインのお陰でListenerが重複しないだけでなく、deinitできる。
        tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        print("------------------------Comment View DEINITIALIZING---------------------")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Helpers
    
    func configureCaptionLabel(){
        
        captionLabel.configureLinkAttribute = postViewModel?.configureLinkAttribute
        captionLabel.enabledTypes = postViewModel?.enabledTypes ?? []
        postViewModel?.customizeLabel(captionLabel)
        
        captionLabel.handleHashtagTap { [weak self] hashtag in
            let vc = HashtagPostsController(hashtag: hashtag.lowercased())
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        captionLabel.handleMentionTap { [weak self] username in
            guard let self = self else {return}
            self.showLoader(true)
            
            UserService.fetchUser(withUsername: username) { (result) in
                switch result{
                case .failure(let error):
                    if error as? CustomError == CustomError.noUserExists{
                        self.showSimpleAlert(title: "User @\(username) does not exist.", message: "", actionTitle: "ok")
                    }else{
                        print("DEBUG: Error fetching user from user name: \(error.localizedDescription)")
                    }
                    return
                    
                case .success(let user):
                    let vc = ProfileController(user: user)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        captionLabel.handleURLTap { [weak self] (url) in
            var urlString = url.absoluteString
            if !(["http", "https"].contains(urlString.lowercased())) {
                urlString = "http://\(urlString)"
            }
            guard let appendedUrl = URL(string: urlString) else{return}
            let vc = SFSafariViewController(url: appendedUrl)
            self?.present(vc, animated: true, completion: nil)
        }
    }
    
    func configureCollectionView() {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.backgroundColor = .white
        collectionView.register(CommentCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        //以下の2つはこの場合はセットで。alwaysBounceVertical = falseにすると2,3itemしかない場合に機能しない。
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
    }
    
    func configureUI(){
        
        navigationItem.title = "Comments"
        view.backgroundColor = .white
        imageView.image = image
        captionLabel.text = caption
        
        view.addSubview(headerView)
        headerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor)
        
        headerView.addSubview(imageView)
        imageView.setDimensions(height: 200, width: 200)
        imageView.centerX(inView: headerView)
        imageView.anchor(top: headerView.topAnchor, paddingTop: 10)
        
        headerView.addSubview(captionLabel)
        captionLabel.anchor(top: imageView.bottomAnchor, left: headerView.leftAnchor, bottom: headerView.bottomAnchor, right: headerView.rightAnchor, paddingTop: 6, paddingLeft: 18, paddingBottom: 10, paddingRight: 12)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: headerView.bottomAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor)
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: commentInputView.frame.height + 10, right: 0)
        
    }
    
    //MARK: - Actions
    
    @objc func collectionViewTapped(){  //キーボードをdismissする
        commentInputView.commentTextView.resignFirstResponder()
    }
    
    
    // MARK: - API
    
    func fetchComments() {

        commentService.fetchComments(forPost: post.postId) { comments in
            
            self.comments = comments
            self.collectionView.reloadData()
            //以下のように２行続けることにより新しいコメントが入った時に上から落ちてくるようなアニメーションをつけることができる。
            self.collectionView.scrollToItem(at: IndexPath(row: 1, section: 0), at: .top, animated: false)
            self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CommentController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CommentCell
        cell.viewModel = CommentViewModel(comment: comments[indexPath.row])
        cell.delegate = self
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CommentController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let viewModel = CommentViewModel(comment: comments[indexPath.row])
        let labelWidth = view.frame.width - 54 - 60
        let height = viewModel.sizeEstimate(forWidth: labelWidth).height + 18
        return CGSize(width: view.frame.width, height: height)
    }
}


// MARK: - CommentCellDelegate

extension CommentController: CommentCellDelegate{  //コメント左のプロファイル写真をタップした時
    
    func cell(_ cell: UICollectionViewCell, showUserProfileFor uid: String) {
        
        UserService.fetchUser(withUid: uid) { (result) in
            switch result{
            case .failure(let error):
                print("Error fetching user: \(error.localizedDescription)")
            case .success(let user):
                let vc = ProfileController(user: user)
                self.navigationController?.pushViewController(vc, animated: true)
                
            }
        }
    }
}


// MARK: - CommentInputAccesoryViewDelegate

extension CommentController: CustomInputAccesoryViewDelegate {  //accessoryViewのsendをタップした時。
    
    func inputView(_ inputView: CustomInputAccesoryView, wantsToUploadText text: String) {
        
        guard let tab = tabBarController as? MainTabController else { return }
        guard let currentUser = tab.user else { return }
        showLoader(true)
        
        CommentService.uploadComment(comment: text, post: post, user: currentUser) { error in
            
            self.showLoader(false)
            self.commentInputView.commentTextView.resignFirstResponder()
            if let error = error{
                print("DEBUG: Error uploading comment. \(error)")
                return
            }
            inputView.clearInputText()
            NotificationService.uploadNotification(toUid: self.post.ownerUid,fromUser: currentUser,
                                                   type: .comment, post: self.post) { (error) in
                if let error = error{
                    print("DEBUG: Error sending comment notification in CommentController: \(error.localizedDescription)")
                }
            }
        }
    }   //現在コメントの削除機能は実装されていない。
    
}

