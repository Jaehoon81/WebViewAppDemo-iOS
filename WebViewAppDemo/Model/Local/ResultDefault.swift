//
//  ResultDefault.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/08.
//

import Foundation

// Native -> WebView(JavaScript)로 전달하는 기본 형태의 데이터 모델
class ResultDefault: Codable {
    
    var uuid: String?
    var action: String
    var result: String
    var isError: Bool
    
    init(uuid: String?, action: String, result: String, isError: Bool) {
        self.uuid = uuid
        self.action = action
        self.result = result
        self.isError = isError
    }
}
