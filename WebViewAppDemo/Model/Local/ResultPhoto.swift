//
//  ResultPhoto.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/15.
//

import Foundation

// Native -> WebView(JavaScript)로 전달하는 사진 이미지 데이터 모델
class ResultPhoto: Codable {
    
    struct PhotoData: Codable {
        var name: String
        var base64Image: String
    }
    
    var uuid: String?
    var action: String
    var result: [PhotoData]
    var isError: Bool
    
    init(uuid: String?, action: String, isError: Bool) {
        self.uuid = uuid
        self.action = action
        self.result = [PhotoData]()
        self.isError = isError
    }
    
    init(uuid: String?, action: String, photoDataList: [PhotoData]) {
        self.uuid = uuid
        self.action = action
        self.result = photoDataList
        self.isError = false
    }
    
    func addPhotoData(name: String, base64Image: String) {
        self.result.append(PhotoData(name: name, base64Image: base64Image))
    }
    
    func addPhotoData(_ data: PhotoData) {
        self.result.append(data)
    }
}
