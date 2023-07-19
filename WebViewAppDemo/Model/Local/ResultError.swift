//
//  ResultError.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/08.
//

import Foundation

enum ErrorCode: LocalizedError {
    
    case invalidAction
    case invalidParameter
    case deniedPermission
    case jsonDataFailure
    case imageDataFailure
    case unknownError
    case emptyParameter
    case emptyData
    case cancelAction
    
    var errorDescription: String? {
        switch self {
        case .invalidAction:    return "잘못된 명령입니다."
        case .invalidParameter: return "유효하지 않은 Parameter 값입니다."
        case .deniedPermission: return "권한이 거부되었습니다."
        case .jsonDataFailure:  return "Json 데이터 생성에 실패하였습니다."
        case .imageDataFailure: return "Image 데이터 생성에 실패하였습니다."
        case .unknownError:     return "알수 없는 오류입니다."
        case .emptyParameter:   return "Parameter 값이 없습니다."
        case .emptyData:        return "데이터가 없습니다."
        case .cancelAction:     return "명령이 취소되었습니다."
        }
    }
}

// Native -> WebView(JavaScript)로 전달하는 에러 형태의 데이터 모델
class ResultError: Codable {
    
    var uuid: String?
    var action: String
    var result: String
    var isError: Bool
    
    init(uuid: String?, action: String, result: String) {
        self.uuid = uuid
        self.action = action
        self.result = result
        self.isError = true
    }
}
