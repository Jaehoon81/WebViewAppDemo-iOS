//
//  NetworkMonitor.swift
//  WebViewAppDemo
//
//  Created by 정재훈 on 2023/07/24.
//

import Foundation
import UIKit
import Network

@available(iOS 12.0, *)
final class NetworkMonitor {
    
    enum ConnectionType {
        case cellular
        case wifi
        case ethernet
        case unknown
    }
    
    static let shared = NetworkMonitor()
    private init() {
        monitor = NWPathMonitor()
    }
    
    private let queue = DispatchQueue.global()
    private let monitor: NWPathMonitor
    
    public private(set) var isConnected: Bool = false
    public private(set) var connectionType: ConnectionType = .unknown
    
    public func startMonitoring() {
        monitor.start(queue: queue)
        
        monitor.pathUpdateHandler = { [weak self] (path) in
            self?.isConnected = (path.status == .satisfied)
            self?.getConnectionType(path)
            
            if self?.isConnected == true {
                print("Network_Connected!")
            } else {
                print("Network_Error!")
                self?.showNetworkAlert()
            }
        }
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
    
    private func getConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
            print("Connection_Type: Cellular")
        } else if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
            print("Connection_Type: WiFi")
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
            print("Connection_Type: Ethernet")
        } else {
            connectionType = .unknown
            print("Connection_Type: Unknown")
        }
    }
    
    private func showNetworkAlert() {
        DispatchQueue.main.async {
            CommonUtils.showSettingsAlert(
                targetVC: UIApplication.shared.windows.first?.rootViewController,
                message: "인터넷 접속 상태를 확인해주세요!")
        }
    }
}
