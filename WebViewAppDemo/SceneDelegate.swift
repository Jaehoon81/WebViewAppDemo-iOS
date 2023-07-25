//
//  SceneDelegate.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/05/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(scene, continue: userActivity)
        } else {
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let incomingURL = userActivity.webpageURL else { return }
        print(#function + " withIncomingURL: \(incomingURL)")
        
        // 앱이 종료된 경우(Not Running)의 DeepLink(=URLScheme) 호출
        checkDeepLink(url: incomingURL)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print(#function + " withUrl: \(url)")
        
        // 일반적인 경우(Foreground)의 DeepLink(=URLScheme) 호출
        checkDeepLink(url: url)
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

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        print(#function)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        print(#function)
        
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        print(#function)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print(#function)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        print(#function)
    }
}
