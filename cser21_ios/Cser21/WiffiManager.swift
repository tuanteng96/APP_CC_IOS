//
//  WiffiManager.swift
//  ezsspa
//
//  Created by HUNG on 15/01/2024.
//  Copyright © 2024 High Sierra. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

class WiFiManager {
    static func getWiFiInfo() -> [String: Any] {
        var wifiInfo = [String: Any]()

        if let interfaces = CNCopySupportedInterfaces() as? [String] {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary? {
                    wifiInfo["SSID"] = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String ?? ""
                    wifiInfo["BSSID"] = interfaceInfo[kCNNetworkInfoKeyBSSID as String] as? String ?? ""
                    break
                }
            }
        }

        return wifiInfo
    }
}
