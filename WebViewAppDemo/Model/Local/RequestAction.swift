//
//  RequestAction.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/08.
//

import Foundation

enum ActionCode: String {
    
    case getDeviceUUID = "getDeviceUUID"
    case showToastMessage = "showToastMessage"
    case showNotiMessage = "showNotiMessage"
    case reloadOtherTabs = "reloadOtherTabs"
    case goToAnotherTab = "goToAnotherTab"
    case showBottomNaviView = "showBottomNaviView"
    case hideBottomNaviView = "hideBottomNaviView"
    case getPhotoImages = "getPhotoImages"
}

// WebView(JavaScript) -> Native로 요청하는 호출동작 데이터 모델
class RequestAction: Codable {
    
    var uuid: String?
    var action: String
    var params: [String]?
}
