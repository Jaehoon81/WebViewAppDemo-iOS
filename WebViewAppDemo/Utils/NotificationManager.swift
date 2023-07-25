//
//  NotificationManager.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/07/24.
//

import Foundation
import UserNotifications

class NotificationManager {
    
    static let notificationID = "notificationID"
    
    static let shared = NotificationManager()
    private init() { }
    
    private lazy var userNotiCenter: UNUserNotificationCenter = {
        let userNotiCenter = UNUserNotificationCenter.current()
        return userNotiCenter
    }()
    
    func requestAuthorization(resultHandler: @escaping (Bool) -> Void) {
        let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        userNotiCenter.requestAuthorization(options: authOptions) { (granted, error) in
            if let error = error {
                print(#function + " withError: \(error)")
                resultHandler(false)
            } else {
                resultHandler(granted)
            }
        }
    }
    
    func showNotification(
        title: String, subtitle: String? = nil, body: String, userInfo: [AnyHashable: Any]? = nil,
        errorHandler: ((String?) -> Void)? = nil
    ) {
        userNotiCenter.getNotificationSettings() { [weak self] (settings) in
//            guard let strongSelf = self else { return }
            
            if settings.authorizationStatus == UNAuthorizationStatus.authorized {
                self?.removeAll()
                
                let content = UNMutableNotificationContent()
                content.title = title
                if subtitle != nil { content.subtitle = subtitle! }
                content.body = "\n" + body
                if userInfo != nil { content.userInfo = userInfo! }
                content.sound = .default
                content.badge = 1
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
//                trigger.nextTriggerDate()
                
                let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger)
                self?.userNotiCenter.add(request) { error in
                    if let error = error {
                        if let errorHandler = errorHandler {
                            errorHandler(error.localizedDescription)
                        }
                    }
                }
            } else {
                if let errorHandler = errorHandler {
                    errorHandler("Denied_Permission")
                }
            }
        }
    }
    
    func removeAll() {
//        userNotiCenter.removeAllDeliveredNotifications()
        userNotiCenter.removeAllPendingNotificationRequests()
    }
    
    func isScheduled() async -> Bool {
//        return await userNotiCenter.deliveredNotifications().count > 0
        return await userNotiCenter.pendingNotificationRequests().count > 0
    }
}
