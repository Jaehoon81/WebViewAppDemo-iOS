//
//  CommonUtils.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/07.
//

import Foundation
import UIKit
import WebKit

class CommonUtils {
    
    internal static func getApplicationVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    }
    
    internal static func getBuildVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    }
    
    public static func showAlert(
        targetVC: UIViewController?, title: String = "알림", message: String,
        completion: (() -> Void)? = nil
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "확인", style: .default) {
            (action: UIAlertAction) -> Void in
            if let completion = completion { completion() }
        }
        alertController.addAction(confirmAction)
        targetVC?.present(alertController, animated: true, completion: nil)
    }
    
    public static func showSettingsAlert(
        targetVC: UIViewController?, title: String = "알림", message: String,
        exitFromApp: Bool = false
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let finishAction = UIAlertAction(title: "종료", style: .destructive) {
            (action: UIAlertAction) -> Void in
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { exit(0) }
        }
        let settingsAction = UIAlertAction(title: "설정", style: .default) {
            (action: UIAlertAction) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                if exitFromApp == true {
                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { exit(0) }
                }
            }
        }
        alertController.addAction(finishAction)
        alertController.addAction(settingsAction)
        targetVC?.present(alertController, animated: true, completion: nil)
    }
    
    public static func showNetworkAlert(
        targetVC: UIViewController?, targetWebView: WKWebView, failedUrl: URL?
    ) {
        print(#function + " withFailedUrl: \(failedUrl!)")
        
        let alertController = UIAlertController(title: "알림", message: "인터넷 접속 상태를 확인해주세요!", preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "재시도", style: .destructive) {
            (action: UIAlertAction) -> Void in
            let request = NSURLRequest(url: failedUrl!)
            targetWebView.load(request as URLRequest)
        }
        let confirmAction = UIAlertAction(title: "확인", style: .default) {
            (action: UIAlertAction) -> Void in
            if targetWebView.canGoBack { targetWebView.goBack() }
        }
        alertController.addAction(retryAction)
        alertController.addAction(confirmAction)
        targetVC?.present(alertController, animated: true, completion: nil)
    }
    
    public static func getInfoPList(key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "Info", withExtension: "plist") else {
            return nil
        }
        guard let dictionary = NSDictionary(contentsOf: url) else {
            return nil
        }
        return dictionary[key] as? String
    }
}

extension String {
    
    var isBlank: Bool {
        return allSatisfy({ $0.isWhitespace })
    }
    
    func removeBlankPrefix() -> String {
        var modifiedStr: String = self
        
        while modifiedStr.hasPrefix(" ") {
            modifiedStr = modifiedStr.substring(from: 1, to: modifiedStr.count - 1)
        }
        return modifiedStr
    }
    
    func removeBlankSuffix() -> String {
        var modifiedStr: String = self
        
        while modifiedStr.hasSuffix(" ") {
            modifiedStr = modifiedStr.substring(from: 0, to: modifiedStr.count - 2)
        }
        return modifiedStr
    }
    
    func removeWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
    
    func substring(from: Int, to: Int) -> String {
        guard from < count, to >= 0, to - from >= 0 else {
            return ""
        }
        let startIndex = index(self.startIndex, offsetBy: from)
        let endIndex = index(self.startIndex, offsetBy: to + 1)
        
        return String(self[startIndex ..< endIndex])
    }
}
