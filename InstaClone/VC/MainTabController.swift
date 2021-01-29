//
//  MainTabController.swift
//  InstaClone
//
//  Created by TAKEBUMI SUZUKI on 1/27/21.
//

import UIKit
import Firebase
import YPImagePicker

//全てのタブは個別のnavigationControllerにembedされる形で生成される。真ん中のタブのみYPImagePickerを全画面でpresentさせ、
//写真選択後はUploadPostControllerをその上にさらに全画面presentさせる。投稿後はfeedタブを選択しつつdismiss。
class MainTabController: UITabBarController {
    
    // MARK: - Lifecycle
    
    //このControllerでfetchUser()を行い、userプロパティにuserを代入する事により、その他のtab生成でfetchしなくてもuserオブジェクトを渡せるようになり効率的。
    //だが、structなので、パスした先でmutateした場合には、ここのuserオブジェクトは古いバージョンのままになっている事に注意。
    var user: User? {  //UserオブジェクトがfetchできたらdidSetが発動しconfigureして各TabのVCをインスタンス化する。
        didSet {
            guard let user = user else { return }
            configureViewControllers(withUser: user) //ProfileControllerのinitでuserが必要なため。
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()    //もしログインしていなかったらLoginController(NavBar付き)をfullScrennでpresent
        fetchUser()    //Userオブジェクトをfetchして、上のuserプロパティに代入
    }
    
    
    // MARK: - API
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser == nil {   //syncなのでDispatchQueueがなくても全く問題なく動く
            let VC = LoginController()
            VC.delegate = self
            let nav = UINavigationController(rootViewController: VC)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    func fetchUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        UserService.fetchUser(withUid: uid) { user in
            self.user = user
        }
    }
    
    
    
    // MARK: - Helpers
    
    //ここのtabbar内でのインスタンス化に限らず(普通に新しいページをpresentする場合でも)、viewControllersのviewDidLoadはlazy的に実行される。
    //nextViewController.view.backgroundColor = .red などのラインがあった場合のみその時点で次ページのviewDidLoadが実行される。
    //また、tabbarの各VCのlifecycleをさらに調べたところ、viewDidLoadは初回のみ。以降はviewWillAppearとviewWillDisAppearのみ呼ばれる。
    //deinitは呼ばれない。EditProfileController(presentされる)を調べたところ、viewDidLoadもdeinitも毎回表示非表示のたびに必ず呼ばれる。
    
    func configureViewControllers(withUser user: User) {
        
        view.backgroundColor = .white  //結局各tabのVCに隠されるのでこの設定の意味はない。コメントアウトしてもok
        tabBar.tintColor = .black  //tabBar内部のアイコンの色
        self.delegate = self  //UITabBarControllerDelegateを使う為に必要なライン
        
        let layout = UICollectionViewFlowLayout()
        let feed = templateNavigationController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: FeedController(collectionViewLayout: layout))
        
        let search = templateNavigationController(unselectedImage: #imageLiteral(resourceName: "search_unselected"), selectedImage: #imageLiteral(resourceName: "search_selected"), rootViewController: SearchController(config: .all))
        
        let dummyVC = templateNavigationController(unselectedImage: #imageLiteral(resourceName: "plus_unselected"), selectedImage: #imageLiteral(resourceName: "plus_unselected"), rootViewController: DummyVC()) //このページは実際には使っていないのでダミー。
        
        let notifications = templateNavigationController(unselectedImage: #imageLiteral(resourceName: "like_unselected"), selectedImage: #imageLiteral(resourceName: "like_selected"), rootViewController: NotificationsController())
        
        let profileController = ProfileController(user: user)
        let profile = templateNavigationController(unselectedImage: #imageLiteral(resourceName: "profile_unselected"), selectedImage: #imageLiteral(resourceName: "profile_selected"), rootViewController: profileController)
        
        viewControllers = [feed, search, dummyVC, notifications, profile]
    }
    
    
    func templateNavigationController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController) -> UINavigationController {
        
        let nav = UINavigationController(rootViewController: rootViewController)
        nav.tabBarItem.image = unselectedImage
        nav.tabBarItem.selectedImage = selectedImage
        nav.navigationBar.tintColor = .black  //navBarの左右のアイコンを黒にする為
        return nav
    }
    
}


// MARK: - AuthenticationDelegate

extension MainTabController: AuthenticationDelegate {  //loginControllerなどでユーザーがログインに成功した時に呼ばれる。
    
    func authenticationDidComplete() {
        fetchUser()  //firebaseでユーザーが切り替わった時に前の情報がそのまま表示されてしまう問題を解決する為。
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITabBarControllerDelegate

extension MainTabController: UITabBarControllerDelegate {
    
    //tabBarの各タブがタップされた時に呼ばれ、そのまま通常通りそのtabのVCを表示するか(true)しないか(false)。
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        //firstIndexとはswift文法のArrayに属するmethodで、最初に出てくる要素のindexNumberを返す。
        let index = viewControllers?.firstIndex(of: viewController) //このviewControllerとは引数に代入されている単体VCの事
        
        if index == 2 {  //indexの型はオプショナル、つまりOptional(2)だが、==2として合致する
            var config = YPImagePickerConfiguration()
            config.library.mediaType = .photo
            config.shouldSaveNewPicturesToAlbum = false
            config.startOnScreen = .library
            config.screens = [.library]
            config.hidesStatusBar = false
            config.hidesBottomBar = false
            config.library.maxNumberOfItems = 1

            let picker = YPImagePicker(configuration: config)
            picker.modalPresentationStyle = .fullScreen
            present(picker, animated: true, completion: nil)

            didFinishPickingMedia(picker)  //上にあるメソッドの事。

            return false
            //ここはtrueにしても同じ結果になると一見思われるが、trueだと画像選択をキャンセルした後に真ん中のtabのまま
            //残ってしまい、元の画面に戻れなくなるので、falseにするのが正解。
        }
        
        return true
    }
    
    func didFinishPickingMedia(_ picker: YPImagePicker) {
        
        picker.didFinishPicking { items, _ in
            picker.dismiss(animated: false) {  //一度ここでpickerをdismissし、その後新たにUploadPostをpresentしている。
                guard let selectedImage = items.singlePhoto?.image else { return }

                let VC = UploadPostController()
                //UploadPostController(selectedImage: selectedImage)のようにカスタムイニシャライザを使うようにしても良いとの事
                VC.selectedImage = selectedImage
                VC.delegate = self  //shareボタンを押した後に、APIでポストを保存し、このページで残る処理を行う。下のメソッド
                VC.currentUser = self.user

                let nav = UINavigationController(rootViewController: VC)  //UploadPostControllerを入れたnavをpresent
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: false, completion: nil)
            }
        }
    }
}

// MARK: - UploadPostControllerDelegate

extension MainTabController: UploadPostControllerDelegate {  //ポストした後に呼ばれる
    
    func controllerDidFinishUploadingPost(_ controller: UploadPostController) {
        
        selectedIndex = 0  //feedページを選択して
        controller.dismiss(animated: true, completion: nil)  //controllerのところはself.でもok.よって上の引数も実はいらない。
        
        //feed画面でポストをアップデート。notificationCenterを使っても良いかと。
        guard let feedNav = viewControllers?.first as? UINavigationController else { return }
        guard let feed = feedNav.viewControllers.first as? FeedController else { return }
        feed.handleRefresh()
    }
}
