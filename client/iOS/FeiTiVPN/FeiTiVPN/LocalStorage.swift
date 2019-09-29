//
//  LocalStorage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 5/2/16.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation
import UIKit
import AdSupport

class LocalStorage {
    static let _fileManager = FileManager()
    static let _filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    static let _userInfoFileName = "user_info"
    static let _hashInfoFileName = "hash_info"

    static var CachedToken: String?
    static var CachedUser: UserData?
    static var CachedServers: [ServerData]?
    static var CachedAd: AdData?
    static var CachedNotifications: [NotificationData]?
    static var CachedSupportEmail: String?
    static var CachedIAPIDs: [String]?
    static var CachedIAPs: [IAPData]?
    static var CachedServerHash: String?
    static var CachedNotificationHash: String?
    static var CanManuallySignIn = false
    static var AutoSignIn = true
    static var IFNA: String {
        get {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }
    }
    static var UUID: String {
        get {
            if let uuid = UIDevice.current.identifierForVendor {
                return uuid.uuidString
            }
            return ""
        }
    }
    static var DUID: String {
        get {
            return UIDevice.current.name
        }
    }
    
    static var HasNewServer: Bool {
        get {
            if let localHash = LocalStorage.ReadHashInfo() {
                if let serverHash = LocalStorage.CachedServerHash, let localServerHash = localHash.value(forKey: "server") as? String, localServerHash == serverHash {
                    return false
                }
            }
            return true
        }
    }
    
    static var HasNewNotification: Bool {
        get {
            if let localHash = LocalStorage.ReadHashInfo() {
                if let notificationHash = LocalStorage.CachedNotificationHash, let localNotificationHash = localHash.value(forKey: "notification") as? String, localNotificationHash == notificationHash {
                    return false
                }
            }
            return true
        }
    }
    
    static func ReadUserInfo() -> NSDictionary? {
        if let user_info_data = _fileManager.contents(atPath: "\(_filePath)/\(_userInfoFileName)") {
            do {
                if let user_info = try JSONSerialization.jsonObject(with: user_info_data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary, user_info.count > 0 {
                    return user_info
                }
            }
            catch { }
        }
        return nil
    }
    
    static func SaveUserInfo(account: String, password: String) -> Bool {
        do {
            let user_info = "{\"account\":\"\(account)\", \"password\": \"\(password)\"}"
            try user_info.write(toFile: "\(_filePath)/\(_userInfoFileName)", atomically: false, encoding: String.Encoding.utf8)
            return true
        }
        catch { }
        return false
    }
    
    static func ReadHashInfo() -> NSDictionary? {
        if let hash_info_data = _fileManager.contents(atPath: "\(_filePath)/\(_hashInfoFileName)") {
            do {
                if let hash_info = try JSONSerialization.jsonObject(with: hash_info_data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary, hash_info.count > 0 {
                    return hash_info
                }
            }
            catch { }
        }
        return nil
    }
    
    static func SaveHashInfo(name: String, value: String) -> Bool {
        var content = "{"
        var found = false
        if let dict = ReadHashInfo() {
            for item in dict {
                if let key = item.key as? String {
                    if key == name {
                        content += "\"\(name)\": \"\(value)\", "
                        found = true
                    }
                    else {
                        content += "\"\(key)\": \"\(item.value)\", "
                    }
                }
            }
        }
        
        if !found {
            content += "\"\(name)\": \"\(value)\", "
        }
        
        content += "}"
        content = content.replacingOccurrences(of: ", }", with: "}")
        if content.count > 5 {
            do {
                try content.write(toFile: "\(_filePath)/\(_hashInfoFileName)", atomically: false, encoding: String.Encoding.utf8)
                return true
            }
            catch {}
        }
        return false
    }
    
    static func ReadManualFile(filename: String) -> Data? {
        if let filepath = Bundle.main.path(forResource: filename, ofType: nil) {
            let fileUrl = URL(fileURLWithPath: filepath)
            do {
                return try Data(contentsOf: fileUrl, options: Data.ReadingOptions.alwaysMapped)
            }
            catch {}
        }
        return nil
    }
}
