//
//  PhotoImageService.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/06/15.
//

import Foundation
import UIKit
import Photos
import BSImagePicker

class PhotoImageService: NSObject {
    
//    struct PhotoData {
//        var name: String?
//        var base64Image: String?
//    }
    
    override init() {
        super.init()
        print("PhotoImageService_Init")
        
//        self.selfObject = self
    }
    deinit {
        print("PhotoImageService_Deinit")
    }
    
    public typealias PhotoPickerCompletion =
    (_ sender: PhotoImageService, _ assets: [PHAsset]?, _ error: Error?) -> ()
    public typealias PhotoImagesCompletion =
    (_ sender: PhotoImageService, _ images: [UIImage?]?, _ error: Error?) -> ()
    
    private var photoPickerCompletion: PhotoPickerCompletion?
    private var photoImagesCompletion: PhotoImagesCompletion?
    
    private var selfObject: PhotoImageService?
    
    func requestAuthorization(targetVC: UIViewController) async throws -> (Void) {
        typealias PostContinuation = CheckedContinuation<(Void), Error>
        
        return try await withCheckedThrowingContinuation({
            [weak self] (continuation: PostContinuation) in
            self?.requestAuthorization(targetVC: targetVC, completion: {
                (sender, success) in
                if success == true {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: ErrorCode.deniedPermission)
                }
            })
        })
    }
    
    private func requestAuthorization(targetVC: UIViewController, completion: @escaping (PhotoImageService, Bool) -> ()) {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                processAuthorization(status: status)
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                processAuthorization(status: status)
            }
        }
        func processAuthorization(status: PHAuthorizationStatus) {
            switch status {
            case .authorized, .limited:
                // 모든 사진 or 선택된 사진 접근 권한이 허용되었을 경우
                completion(self, true)
            default:
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    // 설정 화면으로 이동할 수 없을 경우
                    completion(self, false)
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    DispatchQueue.main.async {
                        CommonUtils.showAlert(targetVC: targetVC, title: "사진권한 요청", message: "이 기능을 사용하기 위해서는 사진 권한을 허용해야합니다.") {
                            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                        }
                    }
                }
                completion(self, false)
            }
        }
    }
    
    func openPhotoPicker(targetVC: UIViewController, maxSelection: Int) async throws -> ([PHAsset]) {
        typealias PostContinuation = CheckedContinuation<([PHAsset]), Error>
        
        return try await withCheckedThrowingContinuation({
            [weak self] (continuation: PostContinuation) in
            self?.openPhotoPicker(targetVC: targetVC, maxSelection: maxSelection, completion: {
                (sender, assets, error) in
                if let assets = assets {
                    continuation.resume(returning: assets)
                } else {
                    continuation.resume(throwing: error.unsafelyUnwrapped)
                }
            })
        })
    }
    
    private func openPhotoPicker(targetVC: UIViewController, maxSelection: Int, completion: @escaping PhotoPickerCompletion) {
        photoPickerCompletion = completion
        
        let imagePicker = ImagePickerController()
        imagePicker.albumButton.isHidden = false
        
        imagePicker.settings.selection.max = maxSelection
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.image]
        imagePicker.settings.fetch.album.fetchResults = [
            PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .albumRegular, options: PHFetchOptions()),
            PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: PHFetchOptions())
        ]
        self.selfObject = self
        print(#function)
        
        DispatchQueue.main.async {
            targetVC.presentImagePicker(imagePicker, animated: true,
            select: { [unowned self] (asset) in
                print("Selected: \(asset)")
//                self.selfObject = nil
            },
            deselect: { [unowned self] (asset) in
                print("Deselected: \(asset)")
//                self.selfObject = nil
            },
            cancel: { [unowned self] (assets) in
                print("OpenPhotoPicker_Canceled")
                completion(self, nil, ErrorCode.cancelAction)
                self.selfObject = nil
            },
            finish: { [unowned self] (assets) in
                print("OpenPhotoPicker_Finished")
                completion(self, assets, nil)
                self.selfObject = nil
            })
        }
    }
    
    func getPhotoImages(assets: [PHAsset], width: Int, height: Int) async throws -> ([UIImage?]) {
        typealias PostContinuation = CheckedContinuation<([UIImage?]), Error>
        
        return try await withCheckedThrowingContinuation({
            [weak self] (continuation: PostContinuation) in
            self?.getPhotoImages(assets: assets, width: width, height: height, completion: {
                (sender, images, error) in
                if let images = images {
                    continuation.resume(returning: images)
                } else {
                    continuation.resume(throwing: error.unsafelyUnwrapped)
                }
            })
        })
    }
    
    private func getPhotoImages(assets: [PHAsset], width: Int, height: Int, completion: @escaping PhotoImagesCompletion) {
        photoImagesCompletion = completion
        
        var imageSize = CGSize(width: width, height: height)
        if width == 0 || height == 0 {
            imageSize = PHImageManagerMaximumSize
        }
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.resizeMode = .exact
        imageOptions.isSynchronous = true
        
        self.selfObject = self
        print(#function)
        
        var resultImages = [UIImage?]()
        for asset in assets {
            var hasDegraded = false
            PHImageManager.default().requestImage(
                for: asset, targetSize: imageSize, contentMode: .aspectFit, options: imageOptions) { [unowned self] (image, info) in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if isDegraded == true {
                    // 저하된 품질의 이미지가 반환될 경우, 사용하지 않고 리턴 (예: 썸네일 이미지)
                    print("Degraded: \(String(describing: image))")
                    resultImages.append(nil)
                    hasDegraded = true
                    return
                }
                if hasDegraded == false {
                    resultImages.append(image)
                }
            }
        }
        if !resultImages.isEmpty {
            print("GetPhotoImages_Success")
            completion(self, resultImages, nil)
            self.selfObject = nil
        } else {
            print("GetPhotoImages_Failure")
            completion(self, nil, ErrorCode.imageDataFailure)
            self.selfObject = nil
        }
    }
    
    func convertImageToBase64(image: UIImage?) -> String? {
//        let base64Image = image?.jpegData(compressionQuality: 1.0)?.base64EncodedString()
        let base64Image = image?.pngData()?.base64EncodedString()
        
        return base64Image
    }
}
