//
//  ContainerViewController.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/05/22.
//

import UIKit

class ContainerViewController: UIViewController, ScrollDelegate {
    
    private lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        return vc
    }()
    
    private lazy var bottomNaviView: BottomNaviView = {
        let view = BottomNaviView(frame: CGRect(x: 0, y: 0, width: 400, height: 120), parentView: self.view)
        return view
    }()
    
//    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
////        return UIRectEdge.bottom
//        return [.bottom]
//    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    private var viewControllerList = [UIViewController]()
    private var currentTagId: String = ""
    
    private var otherTabsNotiToken: NSObjectProtocol?
    private var anotherTabNotiToken: NSObjectProtocol?
    private var bottomNaviViewNotiToken: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ContainerViewController:: " + #function + "_\(currentTagId)")
        
        requestAuthorizations()
        configureNavigationBar()
        
        setupViewControllers()
        setupPageViewController()
        setupBottomNavigationView()
        setupNotificationCenter()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ContainerViewController:: " + #function + "_\(currentTagId)")
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("ContainerViewController:: " + #function + "_\(currentTagId)")
        
        // 앱을 종료하기 전에 WebVC와 NativeVC의 리소스를 해제한다.
        for (index, targetVC) in viewControllerList.enumerated() {
            if [0, 1, 2].contains(index) {
                (targetVC as? WebViewController)?.releaseResources()
            } else {  // 네이티브 화면(f3)일 경우
                (targetVC as? NativeViewController)?.releaseResources()
            }
        }
        // 등록된 NotificationCenter의 Observer도 제거한다.
        if let otherTabsNotiToken = otherTabsNotiToken,
            let anotherTabNotiToken = anotherTabNotiToken,
            let bottomNaviViewNotiToken = bottomNaviViewNotiToken {
            NotificationCenter.default.removeObserver(otherTabsNotiToken)
            NotificationCenter.default.removeObserver(anotherTabNotiToken)
            NotificationCenter.default.removeObserver(bottomNaviViewNotiToken)
        }
    }
    
    private func requestAuthorizations() {
        NotificationManager.shared.requestAuthorization() { granted in
            if granted == false {
                DispatchQueue.main.async {
                    CommonUtils.showSettingsAlert(
                        targetVC: self,
                        title: "알림권한 요청", message: "이 앱을 사용하기 위해서는 알림 권한을 허용해야합니다.",
                        exitFromApp: true)
                }
                return
            }
        }
    }
    
    private func configureNavigationBar() {
        var arrowBackwardImage: UIImage?
        var arrowForwardImage: UIImage?
        
        if #available(iOS 15.0, *) {
            arrowBackwardImage = UIImage(systemName: "arrow.backward", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.black]))
            arrowForwardImage = UIImage(systemName: "arrow.forward", withConfiguration: UIImage.SymbolConfiguration(paletteColors: [.black]))
        } else {
            arrowBackwardImage = UIImage(systemName: "arrow.backward")
            arrowForwardImage = UIImage(systemName: "arrow.forward")
        }
        let arrowBackwardItem = UIBarButtonItem(image: arrowBackwardImage, style: .done, target: self, action: #selector(handleWebViewNavigation(sender:)))
        let arrowForwardItem = UIBarButtonItem(image: arrowForwardImage, style: .done, target: self, action: #selector(handleWebViewNavigation(sender:)))
        arrowBackwardItem.tag = 0
        arrowForwardItem.tag = 1
        
        self.navigationItem.leftBarButtonItem = arrowBackwardItem
        self.navigationItem.rightBarButtonItem = arrowForwardItem
    }
    
    @objc func handleWebViewNavigation(sender: UIBarButtonItem) {
        if !currentTagId.isEmpty {
            let secondIndex = currentTagId.index(after: currentTagId.startIndex)
            let secondChar = currentTagId[secondIndex]
            if let index = secondChar.wholeNumberValue {
                
                let targetVC = viewControllerList[index]
                if sender.tag == 0 {
                    (targetVC as? WebViewController)?.goBack(completion: {
                        [weak self] (canGoBack) in
                        if canGoBack == false {
                            DispatchQueue.main.async {
                                CommonUtils.showAlert(targetVC: self, message: "이전 페이지가 없습니다.")
                            }
                        }
                    })
                } else {  // sender.tag == 1
                    (targetVC as? WebViewController)?.goForward(completion: {
                        [weak self] (canGoForward) in
                        if canGoForward == false {
                            DispatchQueue.main.async {
                                CommonUtils.showAlert(targetVC: self, message: "이후 페이지가 없습니다.")
                            }
                        }
                    })
                }
            }
        }
    }
    
    private func setupViewControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let vc1 = storyboard.instantiateViewController(withIdentifier: "WebView")
        (vc1 as? WebViewController)?.tagId = Constants.BottomTabs.TAG_1
        (vc1 as? WebViewController)?.defaultUrl = Constants.BottomTabs.URL_1
        (vc1 as? WebViewController)?.scrollDelegate = self
        
        let vc2 = storyboard.instantiateViewController(withIdentifier: "WebView")
        (vc2 as? WebViewController)?.tagId = Constants.BottomTabs.TAG_2
        (vc2 as? WebViewController)?.defaultUrl = Constants.BottomTabs.URL_2
        (vc2 as? WebViewController)?.scrollDelegate = self
        
        let vc3 = storyboard.instantiateViewController(withIdentifier: "WebView")
        (vc3 as? WebViewController)?.tagId = Constants.BottomTabs.TAG_3
        (vc3 as? WebViewController)?.defaultUrl = Constants.BottomTabs.URL_3
        (vc3 as? WebViewController)?.scrollDelegate = self
        
        let vc4 = storyboard.instantiateViewController(withIdentifier: "NativeView")
        (vc4 as? NativeViewController)?.tagId = Constants.BottomTabs.TAG_4
        (vc4 as? NativeViewController)?.scrollDelegate = self
        
        viewControllerList.append(vc1)
        viewControllerList.append(vc2)
        viewControllerList.append(vc3)
        viewControllerList.append(vc4)
    }
    
    private func setupPageViewController() {
        self.addChild(pageViewController)
        self.view.addSubview(pageViewController.view)
        
        pageViewController.view.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        pageViewController.didMove(toParent: self)
    }
    
    private func setupBottomNavigationView() {
        // BottomTab을 눌렀을 때, PageView에 해당 View를 연동
        bottomNaviView.addSelectListener { [weak self] (sender, index, reloadView) in
            Preferences.shared.setData(key: .bottomTabIndex, value: index)
            print("Selected_BottomTabIndex = \(index)")
            
            if let targetVC = self?.viewControllerList[index] {
                self?.pageViewController.setViewControllers(
                    [targetVC], direction: .forward, animated: false, completion: nil)
                
                // 현재 탭이 웹 페이지(f0, f1, f2)인 경우, 상단 내비게이션 바를 노출한다.
                self?.navigationController?.isNavigationBarHidden =
                !(index == 0 || index == 1 || index == 2)
                // 현재 탭을 다시 눌렀을 때는 해당 웹뷰의 초기 Url로 리로드한다.
                if reloadView == true {
                    if "f\(index)" == self?.currentTagId {
                        if [0, 1, 2].contains(index) {
                            (targetVC as? WebViewController)?.reloadWebView()
                        } else {  // 네이티브 화면(f3)일 경우
                            (targetVC as? NativeViewController)?.refreshNativeView()
                        }
                    }
                }
                self?.currentTagId = "f\(index)"
            }
        }
        if let index = Preferences.shared.getData(key: .bottomTabIndex) {
//            pageViewController.setViewControllers(
//                [viewControllerList[index]], direction: .forward, animated: false, completion: nil)
            bottomNaviView.selectBottomTab(index: index)
        } else {
//            pageViewController.setViewControllers(
//                [viewControllerList[0]], direction: .forward, animated: false, completion: nil)
            bottomNaviView.selectBottomTab(index: 0)
        }
    }
    
    private func setupNotificationCenter() {
        otherTabsNotiToken = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "otherTabsDidReload"), object: nil, queue: .main) {
                [weak self] (noti) in
                if let tagId = noti.object as? String {
                    for (index, bottomTabTag) in ["f0", "f1", "f2", "f3"].enumerated() {
                        // 현재 탭을 제외하고, 나머지 웹뷰를 초기 Url로 리로드한다.
                        if bottomTabTag == tagId { continue }
                        else {
                            if let targetVC = self?.viewControllerList[index] {
                                if [0, 1, 2].contains(index) {
                                    (targetVC as? WebViewController)?.reloadWebView()
                                } else {  // 네이티브 화면(f3)일 경우
                                    (targetVC as? NativeViewController)?.refreshNativeView()
                                }
                            }
                        }
                    }
                }
            }
        anotherTabNotiToken = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "anotherTabDidMove"), object: nil, queue: .main) {
                [weak self] (noti) in
                if let targetInfo = noti.object as? [String] {
                    if !targetInfo[0].isEmpty,
                        let index = Int(targetInfo[0].substring(from: 1, to: 1)) {
                        if !targetInfo[1].isEmpty,
                            let targetVC = self?.viewControllerList[index] {
                            
                            // 다른 탭으로 이동하고, 웹뷰의 경우 특정 Url을 로드한다.
                            if [0, 1, 2].contains(index) {
                                let targetUrl = /*Constants.BottomTabs.URL_1 + */targetInfo[1]
                                (targetVC as? WebViewController)?.targetUrl = targetUrl
                                (targetVC as? WebViewController)?.loadUrl(targetUrl)
                            } else {  // 네이티브 화면(f3)일 경우
                                (targetVC as? NativeViewController)?.refreshNativeView()
                            }
                        }
                        self?.bottomNaviView.selectBottomTab(index: index, reloadView: false)
                    }
                }
            }
        bottomNaviViewNotiToken = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "isBottomNaviViewHidden"), object: nil, queue: .main) {
                [weak self] (noti) in
                if let isVisible = noti.object as? Bool {
                    if isVisible == true {
                        self?.bottomNaviView.isHidden = false
                    } else {
                        self?.bottomNaviView.isHidden = true
                    }
                }
            }
    }
    
    func didScroll(isUp: Bool) {
//        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        if isUp == true {
            UIView.animate(withDuration: 0.4) {
                self.bottomNaviView.frame.origin.y = UIScreen.main.bounds.maxY - self.bottomNaviView.frame.height
            }
        } else {
            UIView.animate(withDuration: 0.4) {
                self.bottomNaviView.frame.origin.y = UIScreen.main.bounds.maxY + self.bottomNaviView.frame.height
            }
        }
    }
}
