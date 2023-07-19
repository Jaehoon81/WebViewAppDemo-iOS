//
//  WebViewController+WKUIDelegate.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/05.
//

import Foundation
import UIKit
import WebKit
import SnapKit
import ProgressHUD

extension WebViewController: WKUIDelegate {
    
    // 웹뷰(JavaScript)에서 alert() 실행 시 호출된다.
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { action in
            completionHandler()
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // 웹뷰(JavaScript)에서 alert()의 확인/취소 클릭 시 호출된다.
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { action in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { action in
            completionHandler(true)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // 웹뷰(JavaScript)에서 alert()의 필드에 텍스트 입력 시 호출된다.
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        weak var alertTextField: UITextField!
        alertController.addTextField(configurationHandler: { textField in
            textField.text = defaultText
            alertTextField = textField
        })
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { action in
            completionHandler(nil)
        }))
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { action in
            completionHandler(alertTextField.text)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // 웹뷰(JavaScript)에서 window.open() 실행 시 호출된다. (새 팝업창 요청)
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print(#function)
        
        let requestUrl = navigationAction.request.url?.absoluteString
        if var url = requestUrl {
            url = url.lowercased()
            if url.starts(with: Constants.BottomTabs.URL_1)
                || url.starts(with: Constants.BottomTabs.URL_2)
                || url.starts(with: Constants.BottomTabs.URL_3)
                || url.starts(with: Constants.BottomTabs.URL_4) {
                // WebViewAppDemo의 주소일 경우, 부모 웹뷰에 로드
                webView.load(navigationAction.request)
                return nil
                
            } else if url.contains("instagram.com")
                || url.contains("facebook.com")
                || url.contains("twitter.com") {
                // SNS 관련 주소의 경우, 내장된 기본 브라우저에 로드
                openUrl(navigationAction.request.url!)
                return nil
                
            } else {
                // 그 밖의 주소인 경우, 새 팝업창으로 로드
                let popupWebView = createWebView(frame: webView.frame, configuration: configuration)
                return popupWebView
            }
        } else {
            return nil
        }
    }
    
    // 웹뷰(JavaScript)에서 window.close() 실행 시 호출된다.
    func webViewDidClose(_ webView: WKWebView) {
        print(#function)
        
        destroyWebView()
    }
    
    // 웹뷰(새 팝업창) 생성 메서드
    private func createWebView(frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        print(#function)
        
        let webView = WKWebView(frame: frame, configuration: configuration)
        let popupWebView = PopupWebView(frame: frame, parentView: self.view)
        popupWebView.addWebView(webView)
        
        popupWebView.addGoBackListener { [weak self] (sender, canGoBack) in
            if canGoBack == false {
                DispatchQueue.main.async {
                    CommonUtils.showAlert(targetVC: self, message: "이전 페이지가 없습니다.")
                }
            }
        }
        popupWebView.addCloseListener { [weak self] (sender) in
            if let firstIndex = self?.popupWebViewList.firstIndex(of: popupWebView) {
                // 팝업 웹뷰 리스트에서 팝업창을 삭제하고,
                self?.popupProgressViewList.remove(at: firstIndex)
                self?.popupWebViewList.remove(at: firstIndex)
            }
            // 화면에서도 제거
            sender.removeFromSuperview()
            print("PopupWebViewList_Count = \((self?.popupWebViewList.count)!)")
            
            if self?.popupProgressViewList.count == 0 {  // 마지막 팝업창이 종료됐다면
                self?.navigationController?.isNavigationBarHidden = false
                self?.progressView.alpha = 0.0
                self?.progressView.isHidden = true
            }
        }
        // 팝업 웹뷰 리스트에 새 팝업창을 추가
        popupWebViewList.append(popupWebView)
        popupProgressViewList.append(popupWebView.progressView)
        print("PopupWebViewList_Count = \(popupWebViewList.count)")
        
        // 스크롤 방향을 밑으로 하여 BottomNavigationView를 숨김
        scrollDelegate?.didScroll(isUp: false)
        
        self.navigationController?.isNavigationBarHidden = true
        webView.uiDelegate = self
        webView.navigationDelegate = self
        return webView
    }
    
    // 웹뷰(기존 생성된) 삭제 메서드
    private func destroyWebView() {
        print(#function)
        
        // 팝업 웹뷰 리스트에서 팝업창을 삭제하고, 화면에서도 제거
        popupProgressViewList.popLast()?.removeFromSuperview()
        popupWebViewList.popLast()?.removeFromSuperview()
        print("PopupWebViewList_Count = \(popupWebViewList.count)")
        
        if popupProgressViewList.count == 0 {  // 마지막 팝업창이 종료됐다면
            self.navigationController?.isNavigationBarHidden = false
            progressView.alpha = 0.0
            progressView.isHidden = true
        }
    }
    
    // 해당 Url을 외부 브라우저에서 열기
    private func openUrl(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
