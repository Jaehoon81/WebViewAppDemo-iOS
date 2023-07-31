//
//  WebViewController+WKScriptMessageHandler.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/05.
//

import Foundation
import WebKit
import TAKUUID
import MaterialComponents.MaterialSnackbar

extension WebViewController: WKScriptMessageHandler {
    
    // WebView(JavaScript) -> Native의 함수 호출
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "callNative" {
            if let message = message.body as? String {
                
                if let request: RequestAction = decodeJson(json: message) {
                    print("Request_Action: \(request.action)")
                    
                    switch request.action {
                    case ActionCode.getDeviceUUID.rawValue:
                        processGetDeviceUUID(request.uuid, request.action)
                    case ActionCode.showToastMessage.rawValue:
                        processShowToastMessage(request.uuid, request.action, request.params)
                    case ActionCode.showNotiMessage.rawValue:
                        processShowNotiMessage(request.uuid, request.action, request.params)
                    case ActionCode.reloadOtherTabs.rawValue:
                        processReloadOtherTabs(request.uuid, request.action)
                    case ActionCode.goToAnotherTab.rawValue:
                        processGoToAnotherTab(request.uuid, request.action, request.params)
                    case ActionCode.showBottomNaviView.rawValue:
                        processBottomNaviView(request.uuid, request.action, true)
                    case ActionCode.hideBottomNaviView.rawValue:
                        processBottomNaviView(request.uuid, request.action, false)
                    case ActionCode.getPhotoImages.rawValue:
                        processGetPhotoImages(request.uuid, request.action)
                    default:
                        processInvalidAction(request.uuid, request.action)
                    }
                } else {
                    processErrorAction("unknown", message)
                }
            }
        }
    }
    
    /// Json String을 Codable Class로 변환
    /// - Parameter json: Json String
    /// - Returns: Codable Class
    private func decodeJson<T: Codable>(json: String) -> T? {
        let jsonData = json.data(using: .utf8)
        if let data = jsonData {
            let decodedData = try? JSONDecoder().decode(T.self, from: data)
            return decodedData
        }
        return nil
    }
    
    // ===================================================================================================
    // 단말기 고유 ID(=UUID)를 웹뷰로 전달한다.
    private func processGetDeviceUUID(_ uuid: String?, _ action: String) {
        TAKUUIDStorage.sharedInstance().migrate()
        let deviceUuid = TAKUUIDStorage.sharedInstance().findOrCreate()
        print("Device_UUID = \(String(describing: deviceUuid))")
        
        if let deviceUuid = deviceUuid, !deviceUuid.isEmpty {
            let resultData = ResultDefault(uuid: uuid, action: action, result: deviceUuid, isError: false)
            let resultJsonStr = encodeJson(data: resultData) ??
            toErrorJson(uuid: uuid, action: action, error: ErrorCode.jsonDataFailure)
            callJavaScript(resultJsonStr)
        } else {
            let resultJsonStr = toErrorJson(uuid: uuid, action: action, error: ErrorCode.emptyData)
            callJavaScript(resultJsonStr)
        }
    }
    
    // 토스트 메시지를 화면에 노출한다.
    private func processShowToastMessage(_ uuid: String?, _ action: String, _ params: [String]?) {
        guard let params = params, !params.isEmpty else {
            let resultJsonStr = toErrorJson(uuid: uuid, action: action, error: ErrorCode.invalidParameter)
            callJavaScript(resultJsonStr)
            return
        }
        let snackBarMessage = MDCSnackbarMessage()
        snackBarMessage.duration = 2
        snackBarMessage.text = params[0]
        MDCSnackbarManager.default.show(snackBarMessage)
        
        let resultData = ResultDefault(uuid: uuid, action: action, result: params[0], isError: false)
        let resultJsonStr = encodeJson(data: resultData) ??
        toErrorJson(uuid: uuid, action: action, error: ErrorCode.jsonDataFailure)
        callJavaScript(resultJsonStr)
    }
    
    // 노티 메시지를 화면에 노출한다.
    private func processShowNotiMessage(_ uuid: String?, _ action: String, _ params: [String]?) {
        guard let params = params, !params.isEmpty else {
            let resultJsonStr = toErrorJson(uuid: uuid, action: action, error: ErrorCode.invalidParameter)
            callJavaScript(resultJsonStr)
            return
        }
        let body: String? = (params.count == 1) ? nil : params[1]
        let userInfo: [AnyHashable: Any]? = (params.count == 1) ?
            ["title": params[0]] : ["title": params[0], "body": params[1]]
        NotificationManager.shared.showNotification(title: params[0], body: body, userInfo: userInfo) {
            errorMessage in
            if let errorMessage = errorMessage {
                print(#function + " withError: \(errorMessage)")
            }
        }
        let resultData = ResultDefault(uuid: uuid, action: action, result: params[0], isError: false)
        let resultJsonStr = encodeJson(data: resultData) ??
        toErrorJson(uuid: uuid, action: action, error: ErrorCode.jsonDataFailure)
        callJavaScript(resultJsonStr)
    }
    
    // 현재 탭의 웹뷰를 제외하고, 나머지 웹뷰를 리로드한다.
    private func processReloadOtherTabs(_ uuid: String?, _ action: String) {
        mainViewModel.reloadActionTagId = tagId
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: "otherTabsDidReload"), object: tagId)
        
        let resultData = ResultDefault(uuid: uuid, action: action, result: "", isError: false)
        let resultJsonStr = encodeJson(data: resultData) ??
        toErrorJson(uuid: uuid, action: action, error: ErrorCode.jsonDataFailure)
        callJavaScript(resultJsonStr)
    }
    
    // 다른 탭으로 이동하면서 특정 Url을 로드한다.
    private func processGoToAnotherTab(_ uuid: String?, _ action: String, _ params: [String]?) {
        guard let params = params, !params.isEmpty else {
            let resultJsonStr = toErrorJson(uuid: uuid, action: action, error: ErrorCode.invalidParameter)
            callJavaScript(resultJsonStr)
            return
        }
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: "anotherTabDidMove"), object: params)
        
        let resultData = ResultDefault(uuid: uuid, action: action, result: "", isError: false)
        let resultJsonStr = encodeJson(data: resultData) ??
        toErrorJson(uuid: uuid, action: action, error: ErrorCode.jsonDataFailure)
        callJavaScript(resultJsonStr)
    }
    
    // 하단 탭 영역을 보여주거나 숨긴다.
    private func processBottomNaviView(_ uuid: String?, _ action: String, _ isVisible: Bool) {
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: "isBottomNaviViewHidden"), object: isVisible)
        
        let resultData = ResultDefault(uuid: uuid, action: action, result: "", isError: false)
        let resultJsonStr = encodeJson(data: resultData) ??
        toErrorJson(uuid: uuid, action: action, error: ErrorCode.jsonDataFailure)
        callJavaScript(resultJsonStr)
    }
    
    // 사진 앨범에서 이미지를 선택하여 웹뷰로 전달한다.
    private func processGetPhotoImages(_ uuid: String?, _ action: String) {
        Task {
            do {
                let photoImageService = PhotoImageService()
                
                // Step 0. 사진권한 요청
                // (사용자가 거부하면 throws 발생 -> catch 블록 Exception)
                try await photoImageService.requestAuthorization(targetVC: self)
                // Step 1. 사진 앨범을 열어서 이미지 선택
                // (선택된 사진이 없으면 throws 발생)
                let assets = try await photoImageService.openPhotoPicker(targetVC: self, maxSelection: 2)
                // Step 2. assets로부터 이미지 획득
                // 이미지 크기는 width or height 중에 큰 것이 Maximum 1_000이 되고,
                // 나머지 작은 것은 비율에 따라 값이 정해진다.
                // (획득한 사진이 없거나, 알수 없는 오류일 경우 throws 발생)
                let images = try await photoImageService.getPhotoImages(assets: assets,
                    width: 1_000, height: 1_000)
                // Step 3. images를 각각 Base64 이미지로 변환하고,
                // 웹뷰로 전달할 사진 이미지 데이터 모델을 생성한다.
                let resultPhoto = ResultPhoto(uuid: uuid, action: action, isError: false)
                for (index, image) in images.enumerated() {
                    let name = "사진앨범 선택 이미지(\(index + 1))"
                    let base64Image = photoImageService.convertImageToBase64(image: image) ?? ""
                    resultPhoto.addPhotoData(name: name, base64Image: base64Image)
                }
                let resultJsonStr = encodeJson(data: resultPhoto) ??
                toErrorJson(uuid: uuid, action: action, error: ErrorCode.jsonDataFailure)
                callJavaScript(resultJsonStr)
            } catch {
                print(#function + " withException: \(error.localizedDescription)")
                
                let resultJsonStr = toErrorJson(uuid: uuid, action: action, error: error)
                callJavaScript(resultJsonStr)
            }
        }
    }
    
    // ===================================================================================================
    
    private func processInvalidAction(_ uuid: String?, _ action: String) {
        let resultJsonStr = toErrorJson(uuid: uuid, action: action, error: ErrorCode.invalidAction)
        callJavaScript(resultJsonStr)
    }
    
    private func processErrorAction(_ uuid: String?, _ action: String) {
        let resultJsonStr = toErrorJson(uuid: uuid, action: action, error: ErrorCode.unknownError)
        callJavaScript(resultJsonStr)
    }
    
    // ===================================================================================================
    // Native -> WebView(JavaScript)의 함수 호출
    private func callJavaScript(_ param: String?) {
        guard let param = param else { return }
        
        DispatchQueue.main.async {
            self.javaScript(webView: self.webView, callName: "calledByNative", params: [param])
        }
    }
    
    private func callJavaScript(_ params: [String]?) {
        guard let params = params, !params.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.javaScript(webView: self.webView, callName: "calledByNative", params: params)
        }
    }
    
    private func javaScript(webView: WKWebView, callName: String, params: [String]) {
        var javaScriptStr = "javascript:\(callName)("
        for index in 0...(params.count - 1) {
            if index == (params.count - 1) {
                javaScriptStr += "'\(params[index])'"
            } else {
                javaScriptStr += "'\(params[index])', "
            }
        }
        javaScriptStr += ");"
        
        webView.evaluateJavaScript(javaScriptStr) { (any, error) -> Void in
            if error != nil {
                print("JavaScript function call error: \(error.debugDescription)")
            }
        }
    }
    
    // ===================================================================================================
    
    private func toErrorJson(uuid: String?, action: String, error: ErrorCode) -> String {
        let errorMessage = error.errorDescription!
        print("Process(\(action))_Error: \(errorMessage)")
        
        let resultData = ResultError(uuid: uuid, action: action, result: errorMessage)
        let resultJsonStr = encodeJson(data: resultData) ?? ErrorCode.jsonDataFailure.errorDescription!
        return resultJsonStr
    }
    
    private func toErrorJson(uuid: String?, action: String, error: Error?) -> String {
        let errorMessage = error?.localizedDescription ?? ErrorCode.unknownError.errorDescription!
        print("Process(\(action))_Error: \(errorMessage)")
        
        let resultData = ResultError(uuid: uuid, action: action, result: errorMessage)
        let resultJsonStr = encodeJson(data: resultData) ?? ErrorCode.jsonDataFailure.errorDescription!
        return resultJsonStr
    }
    
    /// Codable Class를 Json String으로 변환
    /// - Parameter data: Codable Class
    /// - Returns: Json String
    private func encodeJson<T: Codable>(data: T) -> String? {
        guard let encodedData = try? JSONEncoder().encode(data) else { return nil }
        guard let _ = try? JSONSerialization.jsonObject(with: encodedData) else { return nil }
        
        let jsonStr = String(data: encodedData, encoding: .utf8)
        var resultJsonStr = jsonStr?.replacingOccurrences(of: "\\n", with: "\\\\n")
        resultJsonStr = resultJsonStr?.replacingOccurrences(of: "'", with: "\\'")
        resultJsonStr = resultJsonStr?.replacingOccurrences(of: "\"", with: "\\\"")
        return resultJsonStr
    }
}
