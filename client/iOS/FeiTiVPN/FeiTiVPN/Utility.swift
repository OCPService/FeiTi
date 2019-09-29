//
//  Utility.swift
//  FeiTiVPN
//
//  Created by FeiTi on 29/11/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation
import SystemConfiguration

class Utility {
    static var networkMonitor: SCNetworkReachability? = nil
    static let NetworkStatusNotificationName = NSNotification.Name(rawValue: "ReachabilityStatusChangedNotification")
    
    enum NetworkConnectionStatus {
        case cellular
        case wifi
        case offline
        case unknown
    }
    
    static func NetworkStatus() -> NetworkConnectionStatus {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .unknown
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .unknown
        }
        
        let connectionRequired = flags.contains(.connectionRequired)
        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)
        
        if !connectionRequired && isReachable {
            return isWWAN ? .cellular : .wifi
        }
        
        return .offline
    }
    
    static func StartMonitorNetworkStatus() {
        if networkMonitor == nil {
            let host = "bing.com"
            var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
            if let reachability = SCNetworkReachabilityCreateWithName(nil, host) {
                SCNetworkReachabilitySetCallback(reachability, {(_, flags, _) -> Void in
                    let connectionRequired = flags.contains(.connectionRequired)
                    let isReachable = flags.contains(.reachable)
                    let isWWAN = flags.contains(.isWWAN)
                    let status = (!connectionRequired && isReachable) ? (isWWAN ? NetworkConnectionStatus.cellular: NetworkConnectionStatus.wifi) : NetworkConnectionStatus.offline
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReachabilityStatusChangedNotification"), object: nil, userInfo: ["status": status])
                    
                }, &context)
                if SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), RunLoopMode.commonModes as CFString) {
                    networkMonitor = reachability
                }
            }
        }
    }
    
    static func StopMonitorNetworkStatus() {
        if let reachability = networkMonitor, SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), RunLoopMode.commonModes as CFString) {
            networkMonitor = nil
        }
    }
    
    static func UTCDate(from: String, format: String?) -> Date? {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let dateFormat = format {
            dateFormater.dateFormat = dateFormat
        }
        dateFormater.timeZone = NSTimeZone(abbreviation: "UTC") as TimeZone!
        return dateFormater.date(from: from)
    }

    static func LocalDate(from: Date) -> String {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormater.timeZone = NSTimeZone.local
        return dateFormater.string(from: from)
    }
    
    static func NumberToCurrencyString(number: NSNumber, local: Locale) -> String? {
        let format = NumberFormatter()
        format.formatterBehavior = NumberFormatter.Behavior.behavior10_4
        format.numberStyle = NumberFormatter.Style.currency
        format.locale = local
        return format.string(from: number)
    }
    
    static func IsEmailAddress(email: String) -> Bool {
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailVerify = NSPredicate(format:"SELF MATCHES %@", regEx)
        return emailVerify.evaluate(with: email)
    }
}
