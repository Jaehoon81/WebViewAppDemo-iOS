//
//  WebViewController.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/05/22.
//

import UIKit
import WebKit
import JavaScriptCore
import Combine

class WebViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    let progressView = UIProgressView(progressViewStyle: .default)
    private var progressObserver: NSKeyValueObservation?
    
    var mainViewModel: MainViewModel!
    private var cancelBags = Set<AnyCancellable>()
    
    var tagId: String?
    var defaultUrl: String = ""
    var targetUrl: String = ""
    var scrollDelegate: ScrollDelegate?
    
    var popupWebViewList = [PopupWebView]()
    var popupProgressViewList = [UIProgressView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("WebViewController:: " + #function + "_\(String(describing: tagId))")
        
        mainViewModel = MainViewModel.shared
        mainViewModel.screenActiveStateArr[Int((tagId?.substring(from: 1, to: 1))!)!] = true
        setupObservers()
        
        initWebView()
        initProgressView()
        loadInitialUrl()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("WebViewController:: " + #function + "_\(String(describing: tagId))")
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("WebViewController:: " + #function + "_\(String(describing: tagId))")
        
    }
    
    func releaseResources() {
        print("WebViewController:: " + #function + "_\(String(describing: tagId))")
        
        progressObserver?.invalidate()
    }
    
    private func setupObservers() {
        // ReloadOtherTabs 액션 실행 시, NativeVC에서 API를 호출한 결과를 받기 위한 구독설정
        mainViewModel.employeesCallResult
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error): print("Failure: \(error.localizedDescription)")
                case .finished: print("EmployeesCallResult_Finished")
                }
            } receiveValue: { [weak self] (employees) in
                if let reloadActionTagId = self?.mainViewModel.reloadActionTagId,
                    reloadActionTagId == self?.tagId {
                    self?.mainViewModel.reloadActionTagId = ""
                    
                    if let employees = employees {
                        if employees.status == "error" {
                            CommonUtils.showAlert(targetVC: self, message: "API 호출 에러!!")
                        } else if employees.status == "success" {
                            CommonUtils.showAlert(targetVC: self, message: "API 호출 성공!!")
                        }
                    }
                }
            }.store(in: &cancelBags)
    }
    
    private func initWebView() {
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always
        
        let configuration = WKWebViewConfiguration.init()
        configuration.processPool = WebViewProcessPool.shared
        configuration.userContentController.add(self, name: "callNative")
        configuration.allowsInlineMediaPlayback = false
        
        let frame = webView.frame
        webView.removeFromSuperview()
        webView = WKWebView.init(frame: frame, configuration: configuration)
        self.view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.view.safeAreaLayoutGuide)
//            make.bottom.equalTo(self.view)
            make.bottom.equalToSuperview()
        }
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.delegate = self
        webView.scrollView.bounces = false
        
        webView.evaluateJavaScript("navigator.userAgent") { [weak self] (userAgent, error) in
            print("WebView_\(String(describing: self?.tagId))_UserAgent: \(userAgent!)")
            
            self?.webView.customUserAgent =
            "\(userAgent!) WebViewAppDemo(tab:\(String(describing: self?.tagId)))"
        }
    }
    
    private func initProgressView() {
        webView.addSubview(progressView)
        
        progressView.isHidden = true
        progressView.progressTintColor = .systemIndigo
        progressView.snp.removeConstraints()
        progressView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(0)
            make.trailing.equalToSuperview().offset(0)
            make.height.equalTo(2)
        }
        progressObserver = webView.observe(\.estimatedProgress, options: [.new]) {
            [weak self] (webView, _) in
            self?.progressView.progress = Float(webView.estimatedProgress)
        }
    }
    
    private func loadInitialUrl() {
        if defaultUrl.contains("index.html") {
            loadLocalFile()
        } else {
            let initialUrl = (targetUrl.isEmpty) ? defaultUrl : targetUrl
            if let url = URL(string: initialUrl) {
                webView.load(URLRequest(url: url))
            }
        }
    }
    
    private func loadLocalFile() {
        guard let localFilePath = Bundle.main.path(forResource: "index", ofType: "html") else {
            print("The index.html file could not be found.")
            return
        }
        var htmlStr = ""
        do {
            try htmlStr = String(contentsOfFile: localFilePath, encoding: .utf8)
        } catch {
            print("Failed to convert to html string.")
        }
        // Image나 CSS와 같은 Bundle의 Assets에 접근하는 경우, baseURL: Bundle.main.resourceURL
        if webView != nil {
            webView.loadHTMLString(htmlStr, baseURL: URL(string: "https://index.html"))
        } else {
            print("WebView_\(String(describing: tagId)) is not ready yet.")
        }
    }
    
    func reloadWebView() {
        if defaultUrl.contains("index.html") {
            loadLocalFile()
        } else {
            loadUrl(defaultUrl)
        }
    }
    
    func loadUrl(_ targetUrl: String) {
        if let url = URL(string: targetUrl) {
            if webView != nil {
                webView.load(URLRequest(url: url))
            } else {
                print("WebView_\(String(describing: tagId)) is not ready yet.")
            }
        }
    }
    
    func goBack(completion: @escaping (_ canGoBack: Bool) -> Void) {
        let canGoBack = webView.canGoBack
        if canGoBack == true {
            webView.goBack()
        }
        completion(canGoBack)
    }
    
    func goForward(completion: @escaping (_ canGoForward: Bool) -> Void) {
        let canGoForward = webView.canGoForward
        if canGoForward == true {
            webView.goForward()
        }
        completion(canGoForward)
    }
}

extension WebViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0.0 {
            scrollDelegate?.didScroll(isUp: true)
        } else {
            scrollDelegate?.didScroll(isUp: false)
        }
    }
}
