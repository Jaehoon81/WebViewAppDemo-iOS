//
//  WebViewProcessPool.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/02.
//

import Foundation
import WebKit

class WebViewProcessPool {
    
    static let shared = WKProcessPool.init()
    private init() { }
}
