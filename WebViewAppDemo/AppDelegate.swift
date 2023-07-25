//
//  AppDelegate.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/05/22.
//

import Foundation
import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        
        NetworkMonitor.shared.startMonitoring()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // 대상 단말기 버전이 iOS 13 미만인 경우의 DeepLink(=URLScheme) 호출
        checkDeepLink(url: url)
        return true
    }
    
    private func checkDeepLink(url: URL) {
        // 호출 예시: myapp://webviewappdemo?target=1&url=m.nate.com
        // 해당 Url이 특정 Scheme과 Host를 가지고 있는지 확인
        guard url.scheme == "myapp", url.host == "webviewappdemo" else { return }
        // 원하는 Query Parameters가 있는지도 체크
        let urlStr = url.absoluteString
        guard urlStr.contains("target")/*, urlStr.contains("url")*/ else { return }
        
        let urlComponents = URLComponents(string: urlStr)
        let urlQueryItems = urlComponents?.queryItems ?? []
        var deepLinkData = [String: String]()
        urlQueryItems.forEach { deepLinkData[$0.name] = $0.value }
        
        if let targetTagIndex = deepLinkData["target"] {
            let targetTagId = "f\(targetTagIndex)"
            var targetUrl = ""
            // targetUrl이 빈 값으로 전달되면 loadUrl()/refreshNativeView()가 실행되지 않음
            if let encodedUrl = deepLinkData["url"] {
                targetUrl = "https://" + (encodedUrl.removingPercentEncoding ?? "")
            }
            print("TargetTagId = \(targetTagId), TargetUrl: \(targetUrl)")
            
            // 다른 탭으로 이동하면서 특정 Url을 로드한다.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: "anotherTabDidMove"),
                    object: [targetTagId, targetUrl])
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 앱이 Foreground 상태일 때, Notification을 수신하면 호출된다.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let identifier = notification.request.identifier
        if identifier.contains(NotificationManager.notificationID) {
            let userInfo = notification.request.content.userInfo
            print("UserInfo = \(userInfo)")
        }
        if #available(iOS 14.0, *) {
            completionHandler([.list, .banner])
        } else {
            completionHandler([.alert])
        }
    }
    
    // Notification을 수신한 후, 알림을 누르면 호출된다.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        guard let rootViewController = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else {
            print("RootViewController could not be found.")
            
            completionHandler()
            return
        }
        // 알림을 눌렀을 때, 필요한 로직구현 (특정 화면으로 이동)
        let identifier = response.notification.request.identifier
        if identifier.contains(NotificationManager.notificationID) {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let containerVC = storyboard.instantiateViewController(withIdentifier: "ContainerView") as? ContainerViewController,
                let navigationController = rootViewController as? UINavigationController {
                
                let userInfo = response.notification.request.content.userInfo
                print("UserInfo = \(userInfo)")
                
                // showNotification() 함수 호출 시에 전달한 값이 있다면 주석을 해제하고, 필요한 로직을 작성한다.
//                if let _ = userInfo[""] as? String {
//                    containerVC. =
//                }
//                navigationController.pushViewController(containerVC, animated: true)
            }
        }
        completionHandler()
    }
}
