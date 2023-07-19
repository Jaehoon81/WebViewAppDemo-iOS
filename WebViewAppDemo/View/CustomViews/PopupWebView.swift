//
//  PopupWebView.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/05/31.
//

import Foundation
import UIKit
import WebKit
import SnapKit

class PopupWebView: UIView {
    
    @IBOutlet weak var goBackButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var containerView: UIView!
    private var webView: WKWebView?
    
    var progressView = UIProgressView(progressViewStyle: .default)
    private var progressObserver: NSKeyValueObservation?
    
    public typealias GoBackHandler = (_ sender: PopupWebView, _ canGoBack: Bool) -> ()
    private var goBackHandler: GoBackHandler?
    
    func addGoBackListener(handler: @escaping GoBackHandler) {
        goBackHandler = handler
    }
    
    public typealias CloseHandler = (_ sender: PopupWebView) -> ()
    private var closeHandler: CloseHandler?
    
    func addCloseListener(handler: @escaping CloseHandler) {
        closeHandler = handler
    }
    
    @IBAction func onGoBack(_ sender: UIButton) {
        if let webView = webView {
            let canGoBack = webView.canGoBack
            if canGoBack == true {
                webView.goBack()
            }
            goBackHandler?(self, canGoBack)
        } else {
            goBackHandler?(self, false)
        }
    }
    
    @IBAction func onClose(_ sender: UIButton) {
        progressObserver?.invalidate()
        closeHandler?(self)
    }
    
    deinit {
        progressObserver?.invalidate()
    }
    
    init(frame: CGRect, parentView: UIView) {
        super.init(frame: frame)
        setupXib()
        
        parentView.addSubview(self)
        self.snp.removeConstraints()
        self.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(parentView.safeAreaLayoutGuide.snp.top)
//            make.bottom.equalTo(parentView.safeAreaLayoutGuide.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupXib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupXib()
    }
    
    private func setupXib() {
        guard let view = loadViewFromNib(name: "PopupWebView") else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
    }
    
    private func loadViewFromNib(name: String) -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: name, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
        return view
    }
    
    func addWebView(_ webView: WKWebView) {
        goBackButton.setTitle("", for: .normal)
        closeButton.setTitle("", for: .normal)
        
        containerView.addSubview(webView)
        self.webView = webView
        
        webView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        initProgressView()
    }
    
    private func initProgressView() {
        guard let webView = webView else {
            print("PopupWebView is not ready yet.")
            return
        }
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
}
