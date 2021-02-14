//
//  HashtagPostsController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

//profileViewControllerの下部にあるのと同じCell(ProfileCell)とPostViewModelを使い、小さな正方形のポスト一覧を作る。

import UIKit

private let cellIdentifier = "PhotoCell"

class HashtagPostsController: UICollectionViewController {
    
    private var posts = [Post]()
    private let hashtag: String

    // MARK: - Lifecycle
    
    init(hashtag: String) {
        self.hashtag = hashtag
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        fetchPosts()
    }
    
    
    // MARK: - Helpers
    
    private func configureCollectionView() {
        navigationItem.title = "#\(hashtag)"

        collectionView.backgroundColor = .white
        collectionView.register(ProfileCell.self, forCellWithReuseIdentifier: cellIdentifier)
    }
    
    // MARK: - API
    
    private func fetchPosts() {
        PostService.fetchPosts(forHashtag: hashtag) { posts in
            self.posts = posts
            self.collectionView.reloadData()
        }
    }
}


// MARK: - UICollectionViewDataSource

extension HashtagPostsController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ProfileCell
        cell.viewModel = PostViewModel(post: posts[indexPath.row])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension HashtagPostsController: UICollectionViewDelegateFlowLayout {
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
}

// MARK: - UICollectionViewDelegate

extension HashtagPostsController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = FeedController(collectionViewLayout: UICollectionViewFlowLayout())
        vc.post = posts[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
