//
//  APIError.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/19.
//

import Foundation

enum APIError: Error {
    
    case invalidUrl(String?)
    case invalidResponse
    case networkFailure(Int?)
    case unknownError
    case emptyData
    
    var errorMessage: String? {
        switch self {
        case .invalidUrl(let urlString):
            let urlString = (urlString == nil) ? "" : "\(urlString!): "
            return urlString + "잘못된 형식의 URL 주소입니다."
        case .invalidResponse:
            return "잘못된 형식의 응답입니다."
        case .networkFailure(let errorCode):
            let errorCode = (errorCode == nil) ? "" : "\(errorCode!): "
            return errorCode + "네트워크 통신에 실패하였습니다."
        case .unknownError:
            return "알수 없는 네트워크 오류입니다."
        case .emptyData:
            return "데이터가 없습니다."
        }
    }
}
