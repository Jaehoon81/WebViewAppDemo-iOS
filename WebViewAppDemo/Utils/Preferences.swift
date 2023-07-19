//
//  Preferences.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/05/30.
//

import Foundation

enum Key: String {
    
    case permission = "permission"
    case bottomTabIndex = "bottomTabIndex"
}

class Preferences: NSObject {
    
    static let shared = Preferences()
    private override init() { }
    
    func getData(key: Key) -> Int? {
        return UserDefaults.standard.integer(forKey: key.rawValue)
    }
    
    func setData(key: Key, value: Int) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
