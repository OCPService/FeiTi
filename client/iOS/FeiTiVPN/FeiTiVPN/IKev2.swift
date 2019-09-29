//
//  IKev2.swift
//  FeiTiVPN
//
//  Created by FeiTi on 22/11/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Security
import Foundation
import NetworkExtension

class IKev2 {
    static let Instance = IKev2()
    
    var ConnectFailed: (() -> Void)? = nil
    var VPNStatusChanged: ((NEVPNStatus) -> Void)? = nil
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(_VPNStatusDidChanged), name: Notification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func _VPNStatusDidChanged(notification: NSNotification) {
        if let handler = self.VPNStatusChanged {
            let vpnManager = NEVPNManager.shared()
            vpnManager.loadFromPreferences(completionHandler: {(error) -> Void in
                handler(vpnManager.connection.status)
            })
        }
    }
    
    func AddKeyChain(key: String, value: String) {
        if let service = Bundle.main.bundleIdentifier, let keyData = key.data(using: String.Encoding.utf8), let valueData = value.data(using: String.Encoding.utf8) {
            let query = [kSecClass as String : kSecClassGenericPassword,
                         kSecAttrService as String : service,
                         kSecAttrGeneric as String : keyData,
                         kSecAttrAccount as String : keyData,
                         kSecAttrAccessible as String : kSecAttrAccessibleAlwaysThisDeviceOnly,
                         kSecValueData as String : valueData] as [String : Any]
            let status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecSuccess {
                print("Add Key Chain [\(key)] Success")
            }
            else {
                print("Add Key Chain [\(key)] Failed")
            }
        }
    }
    
    func RemoveKeyChain() {
        if let service = Bundle.main.bundleIdentifier {
            let query = [kSecClass as String : kSecClassGenericPassword,
                         kSecAttrService as String: service] as [String : Any]
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                print("Removed Key Chain Success")
            }
            else {
                print("Removed Key Chain Failed")
            }
        }
    }
    
    func GetKeyChainValue(key: String) -> Data? {
        var output: Data? = nil
        if let service = Bundle.main.bundleIdentifier, let keyData = key.data(using: String.Encoding.utf8) {
            let query = [kSecClass as String : kSecClassGenericPassword,
                         kSecAttrService as String : service,
                         kSecAttrGeneric as String : keyData,
                         kSecAttrAccount as String : keyData,
                         kSecAttrAccessible as String : kSecAttrAccessibleAlwaysThisDeviceOnly,
                         kSecMatchLimit as String : kSecMatchLimitOne,
                         kSecReturnPersistentRef as String : kCFBooleanTrue] as [String : Any]
            
            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecSuccess {
                print("Get Key Chain [\(key)] Success")
                output = (result as! Data)
            }
            else {
                print("Get Key Chain [\(key)] Failed")
            }
        }
        return output
    }
    
    func ConnectForXAuthOrEAP(name: String, serverAddress: String, username: String, password: String, sharedSecret: String, remoteIdentifier: String?, localIdentifier: String?, errorHandler: ((_ error: NSError)->Void)? = nil) {
        self.RemoveKeyChain()
        self.AddKeyChain(key: "SharedSecret", value: sharedSecret)
        self.AddKeyChain(key: "Password", value: password)
        
        if let sharedSecret = self.GetKeyChainValue(key: "SharedSecret"), let password = self.GetKeyChainValue(key: "Password") {
            let vpnManager = NEVPNManager.shared()
            vpnManager.isOnDemandEnabled = true
            vpnManager.loadFromPreferences(completionHandler: {(error) -> Void in
                vpnManager.localizedDescription = name
                let connect = NEVPNProtocolIKEv2()
                connect.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
                connect.useExtendedAuthentication = true
                connect.disconnectOnSleep = false
                connect.serverAddress = serverAddress
                if let rid = remoteIdentifier {
                    connect.remoteIdentifier = rid
                }
                if let lid = localIdentifier {
                    connect.localIdentifier = lid
                }
                connect.username = username
                connect.sharedSecretReference = sharedSecret
                connect.passwordReference = password
                
                if #available(iOS 9.0, *) {
                    vpnManager.protocolConfiguration = connect
                } else {
                    vpnManager.protocol = connect
                }
                
                vpnManager.isEnabled = true
                
                vpnManager.saveToPreferences(completionHandler: {(error) -> Void in
                    vpnManager.loadFromPreferences(completionHandler: {(error) -> Void in
                        do {
                            try vpnManager.connection.startVPNTunnel()
                        }
                        catch let error as NSError {
                            if let handler = errorHandler {
                                handler(error)
                            }
                            vpnManager.connection.stopVPNTunnel()
                        }
                    })
                })
            })
        }
    }

    func Disconnect() {
        let vpnManager = NEVPNManager.shared()
        vpnManager.loadFromPreferences(completionHandler: {(error) -> Void in
            vpnManager.connection.stopVPNTunnel()
        })
    }
    
    func GetConnectionStatus(callback: @escaping (NEVPNStatus) -> Void) {
        let vpnManager = NEVPNManager.shared()
        vpnManager.loadFromPreferences(completionHandler: {(error) -> Void in
            callback(vpnManager.connection.status)
        })
    }
}
