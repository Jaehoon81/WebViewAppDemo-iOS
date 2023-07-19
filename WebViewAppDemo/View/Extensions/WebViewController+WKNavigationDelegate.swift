//
//  WebViewController+WKNavigationDelegate.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/05.
//

import Foundation
import UIKit
import WebKit
import SnapKit
import ProgressHUD

extension WebViewController: WKNavigationDelegate {
    
    // 1. 지정된 action 정보를 기반으로 새 콘텐츠로 이동할 수 있는 권한을 요청합니다.
    // 이 메서드를 통해 navigation request를 허용하거나 거부할 수 있습니다.
    // 
    // 구현부에서는 항상 아래와 같은 decisionHandler 블록을 실행합니다.
    // decisionHandler(.allow)
    // decisionHandler(.cancel)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print(#function)
        
        guard let requestUrl = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        let requestUrlStr = requestUrl.absoluteString
        print("RequestUrl_Str: \(requestUrlStr)")
        
        guard let scheme = requestUrl.scheme else {
            decisionHandler(.cancel)
            return
        }
        print("RequestUrl_Scheme: \(scheme)")
        
        // 네이티브 요청 링크(=비 웹 페이지) 처리
        if !scheme.elementsEqual("http") && !scheme.elementsEqual("https") {
            // Case 1. tel, sms, mailto 등의 링크는 기본 내장된 앱을 실행
            if ["tel", "sms", "mailto", "facetime"].contains(scheme) {
                let targetUrlStr = requestUrlStr.components(separatedBy: ":")
                if let targetUrl = NSURL(string: "\(scheme)://\(targetUrlStr[1])") {
                    
                    if UIApplication.shared.canOpenURL(targetUrl as URL) {
                        UIApplication.shared.open(targetUrl as URL, options: [:]) { (isOpened) -> Void in
                            print("\(scheme) app is opened.")
                        }
                    }
                }
            }
            // Case 2. isp, payco, bankpay 결제 서비스 앱은 미설치 시, 아래와 같이 추가 처리가 필요
            // 나머지 앱들은 미설치 시, else 구문에서 해당 앱 스토어로 이동
            else if scheme == "ispmobile" && !UIApplication.shared.canOpenURL(requestUrl) {
                openUrl(URL(string: "http://itunes.apple.com/kr/app/id369125087?mt=8")!)
            } else if scheme == "payco" && !UIApplication.shared.canOpenURL(requestUrl) {
                openUrl(URL(string: "http://itunes.apple.com/kr/app/id924292102?mt=8")!)
            } else if scheme == "kftc-bankpay" && !UIApplication.shared.canOpenURL(requestUrl) {
                openUrl(URL(string: "http://itunes.apple.com/us/app/id398456030?mt=8")!)
            }
            // Case 3. 그 밖의 기타 요청은 requestUrl을 그대로 호출
            else {
                openUrl(requestUrl)
            }
            decisionHandler(.cancel)
            return
        }
        // 정상적인 링크(=일반 웹 페이지) 처리
        else if navigationAction.navigationType == .linkActivated {
            print("A normal link request.")
            decisionHandler(.allow)
        }
        // 코드 상에서 웹 페이지 로드
        else {
            print("Not a click from the user.")
            decisionHandler(.allow)
        }
    }
    
    // 2-1. 메인 프레임에서 navigation이 시작되었음을 알립니다.
    // 웹뷰는 navigation request를 처리하기 위한 임시(provisional) 허가를 받은 후,
    // 해당 요청에 대한 응답을 받기 전에 이 메서드를 호출합니다.
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
        
        progressView.isHidden = false
        UIView.animate(withDuration: 0.33) {
            self.progressView.alpha = 1.0
        }
        if popupProgressViewList.count != 0 {
            popupProgressViewList.last?.isHidden = false
            UIView.animate(withDuration: 0.33) {
                self.popupProgressViewList.last?.alpha = 1.0
            }
        }
    }
    
    // 2-2. 초기 navigation 프로세스 중에 오류가 발생했음을 알립니다.
    // (url이 잘못되었거나 네트워크 오류가 발생하여 웹 페이지 자체를 불러오지 못했을 때 호출되는 메서드)
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(#function + " withError: \(error)")
        
        let failedUrl = (error as NSError).userInfo["NSErrorFailingURLStringKey"] as? String
        let errorCode = (error as NSError).code
        print("Request_ErrorCode = \(errorCode)")
        
        if errorCode >= 400 || errorCode == -1009 {
            resetProgressViews()
            DispatchQueue.main.async {
                CommonUtils.showNetworkAlert(targetVC: self, targetWebView: webView, failedUrl: URL(string: failedUrl!))
            }
        }
    }
    
    // 3. navigation request에 대한 응답을 받고 난 후, 새 콘텐츠로 이동할 수 있는 권한을 요청합니다.
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print(#function)
        
        if let response = navigationResponse.response as? HTTPURLResponse {
            let statusCode = response.statusCode
            print("Response_StatusCode = \(statusCode)")
            
            if statusCode == 404 {
                resetProgressViews()
                DispatchQueue.main.async {
                    CommonUtils.showNetworkAlert(targetVC: self, targetWebView: webView, failedUrl: response.url)
                }
            }
        }
        decisionHandler(.allow)
    }
    
    // 4-1. 웹뷰가 메인 프레임에 대한 내용을 수신하기 시작했음을 알립니다.
    // 변경 사항이 준비되면 웹뷰는 main frame 업데이트를 시작하기 직전에 이 메서드를 호출합니다.
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print(#function)
        
    }
    
    // 4-2. navigation 중에 오류가 발생했음을 알립니다.
    // (didCommit 이후에 발생하는 에러에 대한 호출)
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(#function + " withError: \(error)")
        
        resetProgressViews()
    }
    
    // 5. navigation이 완료되었음을 알립니다.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(#function)
        
        UIView.animate(withDuration: 0.33) {
            self.progressView.alpha = 0.0
        } completion: { isFinished in
            self.progressView.isHidden = isFinished
        }
        if popupProgressViewList.count != 0 {
            UIView.animate(withDuration: 0.33) {
                self.popupProgressViewList.last?.alpha = 0.0
            } completion: { isFinished in
                self.popupProgressViewList.last?.isHidden = isFinished
            }
        }
    }
    
    // Https(SSL) 인증 확인에 응답하도록 요청합니다.
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Https_Host: \(challenge.protectionSpace.host)")
        
        if challenge.protectionSpace.host.contains("http") {  // 특정 Url의 포함여부 확인
            // SSL 인증서 무시 프로세스
            let urlCredential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, urlCredential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    // 해당 Url을 외부 브라우저에서 열기
    private func openUrl(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // 화면 상단의 ProgressBar Indicator를 리셋
    private func resetProgressViews() {
        progressView.alpha = 0.0
        progressView.isHidden = true
        
        if popupProgressViewList.count != 0 {
            popupProgressViewList.last?.alpha = 0.0
            popupProgressViewList.last?.isHidden = true
        }
    }
}
