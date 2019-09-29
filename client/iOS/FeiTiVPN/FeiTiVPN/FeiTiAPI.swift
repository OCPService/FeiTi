//
//  FeiTiAPI.swift
//  FeiTiVPN
//
//  Created by FeiTi on 27/11/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation

class FeiTiAPI: NSObject, URLSessionDelegate {
    static let Instance = FeiTiAPI()
    static let host = "https://api.feitivpn.xyz/"
    var clientCerData: CFArray? = nil
    let requestTimeout = 10.0
    
    override init() {
        super.init()
        self.LoadClientCertificate()
    }
    
    func SignIn(account: String, password: String, success: @escaping () -> Void, failure: @escaping (_ error: FeiTiAPIError) -> Void, completion: (() -> Void)? = nil) {
        let bodyString = "{\"command\": \"v2_ios_sign_in\", \"account\": \"\(account)\", \"password\": \"\(password)\"}"
        self._send_post_request(url: FeiTiAPI.host, data: bodyString, callback: {(data, response, error) -> Void in
            if let error = self._response_handler(data: data, response: response, error: error, success: {(jsonContent) -> Void in
                if let token = jsonContent.value(forKey: "token") as? String, let user = jsonContent.value(forKey: "user") as? NSDictionary, let userData = UserData.parse(from: user), let servers = jsonContent.value(forKey: "servers") as? [NSDictionary], let serversData = ServerData.parse(from: servers), let iap_ids = jsonContent.value(forKey: "iap_ids") as? [String], let iaps = jsonContent.value(forKey: "iap") as? [NSDictionary], let iapsData = IAPData.parse(from: iaps), let ad = jsonContent.value(forKey: "ad") as? NSDictionary, let adData = AdData.parse(from: ad), let notifications = jsonContent.value(forKey: "notifications") as? [NSDictionary], let notificationsData = NotificationData.parse(from: notifications), let supportEmail = jsonContent.value(forKey: "support_mail") as? String, let hash = jsonContent.value(forKey: "hash") as? NSDictionary, hash.count > 0, let serverHash = hash.value(forKey: "server") as? String, let notificationHash = hash.value(forKey: "notification") as? String {
                    LocalStorage.CachedToken = token
                    LocalStorage.CachedUser = userData
                    LocalStorage.CachedServers = serversData
                    LocalStorage.CachedIAPIDs = iap_ids
                    LocalStorage.CachedIAPs = iapsData
                    LocalStorage.CachedAd = adData
                    LocalStorage.CachedNotifications = notificationsData
                    LocalStorage.CachedSupportEmail = supportEmail
                    LocalStorage.CachedServerHash = serverHash
                    LocalStorage.CachedNotificationHash = notificationHash
                    if let canManuallySignIn = jsonContent.value(forKey: "can_manually_sign_in") as? Bool {
                        LocalStorage.CanManuallySignIn = canManuallySignIn
                    }
                    DispatchQueue.main.async {
                        success()
                    }
                }
            }) {
                DispatchQueue.main.async {
                    failure(error)
                }
            }
        })
    }
    
    func SignUp(success: @escaping (_ account: String, _ password: String) -> Void, failure: @escaping (_ error: FeiTiAPIError) -> Void, completion: (() -> Void)? = nil) {
        let body = "{\"command\": \"v2_ios_sign_up\", \"uuid\": \"\(LocalStorage.UUID)\", \"duid\": \"\(LocalStorage.DUID)\", \"ifna\": \"\(LocalStorage.IFNA)\"}"
        self._send_post_request(url: FeiTiAPI.host, data: body, callback: {(data, response, error) -> Void in
            if let error = self._response_handler(data: data, response: response, error: error, success: {(jsonContent) -> Void in
                if let account = jsonContent.value(forKey: "account") as? String, account.characters.count > 0, let password = jsonContent.value(forKey: "password") as? String, password.characters.count > 0 {
                    DispatchQueue.main.async {
                        success(account, password)
                    }
                }
            }) {
                DispatchQueue.main.async {
                    failure(error)
                }
            }
            
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        })
    }
    
    func FreeRefresh(ad_clicked: Bool, ad_presented: Bool, success: @escaping (_ hour: Int, _ points: Int) -> Void, failure: @escaping (_ error: FeiTiAPIError) -> Void, completion: (() -> Void)? = nil) {
        if let token = LocalStorage.CachedToken {
            let bodyString = "{\"command\": \"v2_ios_user_free_refresh\", \"token\": \"\(token)\", \"ad\": \(ad_clicked), \"adp\": \(ad_presented)}"
            self._send_post_request(url: FeiTiAPI.host, data: bodyString, callback: {(data, response, error) -> Void in
                if let error = self._response_handler(data: data, response: response, error: error, success: {(jsonContent) -> Void in
                    if let token = jsonContent.value(forKey: "token") as? String, let user = jsonContent.value(forKey: "user") as? NSDictionary, let userData = UserData.parse(from: user), let hour = jsonContent.value(forKey: "hour") as? Int, let points = jsonContent.value(forKey: "points") as? Int {
                        LocalStorage.CachedToken = token
                        LocalStorage.CachedUser = userData
                        DispatchQueue.main.async {
                            success(hour, points)
                        }
                    }
                }) {
                    DispatchQueue.main.async {
                        failure(error)
                    }
                }
                
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            })
        }
        else {
            failure(FeiTiAPIError.LOCAL_TOKEN_INVALID)
        }
    }
    
    func Purchase(receipt: String, success: @escaping () -> Void, failure: @escaping (_ error: FeiTiAPIError) -> Void, completion: (() -> Void)? = nil) {
        if let token = LocalStorage.CachedToken {
            let bodyString = "{\"command\": \"v2_ios_user_purchase\", \"token\": \"\(token)\", \"receipt\": \"\(receipt)\"}"
            self._send_post_request(url: FeiTiAPI.host, data: bodyString, callback: {(data, response, error) -> Void in
                if let error = self._response_handler(data: data, response: response, error: error, success: {(jsonContent) -> Void in
                    if let token = jsonContent.value(forKey: "token") as? String, let user = jsonContent.value(forKey: "user") as? NSDictionary, let userData = UserData.parse(from: user) {
                        LocalStorage.CachedToken = token
                        LocalStorage.CachedUser = userData
                        DispatchQueue.main.async {
                            success()
                        }
                    }
                }) {
                    DispatchQueue.main.async {
                        failure(error)
                    }
                }
                
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            })
        }
        else {
            failure(FeiTiAPIError.LOCAL_TOKEN_INVALID)
        }
    }
    
    func Point2VIP(points: Int, success: @escaping () -> Void, failure: @escaping (_ error: FeiTiAPIError) -> Void, completion: (() -> Void)? = nil) {
        if let token = LocalStorage.CachedToken {
            let bodyString = "{\"command\": \"v2_ios_user_points_exchange\", \"token\": \"\(token)\", \"points\": \(points)}"
            self._send_post_request(url: FeiTiAPI.host, data: bodyString, callback: {(data, response, error) -> Void in
                if let error = self._response_handler(data: data, response: response, error: error, success: {(jsonContent) -> Void in
                    if let token = jsonContent.value(forKey: "token") as? String, let user = jsonContent.value(forKey: "user") as? NSDictionary, let userData = UserData.parse(from: user) {
                        LocalStorage.CachedToken = token
                        LocalStorage.CachedUser = userData
                        DispatchQueue.main.async {
                            success()
                        }
                    }
                }) {
                    DispatchQueue.main.async {
                        failure(error)
                    }
                }
                
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            })
        }
        else {
            failure(FeiTiAPIError.LOCAL_TOKEN_INVALID)
        }

    }
    
    func AdPresented(success: @escaping () -> Void, failure: @escaping (_ error: FeiTiAPIError) -> Void) {
        if let token = LocalStorage.CachedToken, let ad = LocalStorage.CachedAd {
            let bodyString = "{\"command\": \"v2_ios_ad_presented\", \"token\": \"\(token)\", \"provider\": \"\(ad.Provider)\"}"
            self._send_post_request(url: FeiTiAPI.host, data: bodyString, callback: {(data, response, error) -> Void in
                if let error = self._response_handler(data: data, response: response, error: error, success: {(jsonContent) -> Void in
                    if let token = jsonContent.value(forKey: "token") as? String, let ad = jsonContent.value(forKey: "ad") as? NSDictionary, let adData = AdData.parse(from: ad) {
                        LocalStorage.CachedToken = token
                        LocalStorage.CachedAd = adData
                        DispatchQueue.main.async {
                            success()
                        }
                    }
                }) {
                    DispatchQueue.main.async {
                        failure(error)
                    }
                }
            })
        }
        else {
           failure(FeiTiAPIError.LOCAL_TOKEN_INVALID)
        }
    }
    
    func AdClicked(success: @escaping () -> Void, failure: @escaping (_ error: FeiTiAPIError) -> Void) {
        if let token = LocalStorage.CachedToken, let ad = LocalStorage.CachedAd {
            let bodyString = "{\"command\": \"v2_ios_ad_clicked\", \"token\": \"\(token)\", \"provider\": \"\(ad.Provider)\"}"
            self._send_post_request(url: FeiTiAPI.host, data: bodyString, callback: {(data, response, error) -> Void in
                if let error = self._response_handler(data: data, response: response, error: error, success: {(jsonContent) -> Void in
                    if let token = jsonContent.value(forKey: "token") as? String, let ad = jsonContent.value(forKey: "ad") as? NSDictionary, let adData = AdData.parse(from: ad) {
                        LocalStorage.CachedToken = token
                        LocalStorage.CachedAd = adData
                        DispatchQueue.main.async {
                            success()
                        }
                    }
                }) {
                    DispatchQueue.main.async {
                        failure(error)
                    }
                }
            })
        }
        else {
            failure(FeiTiAPIError.LOCAL_TOKEN_INVALID)
        }
    }
    
    func ChangePassword(password: String, success:@escaping () -> Void, failure: @escaping (_ error: FeiTiAPIError) -> Void, completion: (() -> Void)? = nil) {
        if let token = LocalStorage.CachedToken {
            let bodyString = "{\"command\": \"v2_ios_user_update_password\", \"token\": \"\(token)\", \"password\": \"\(password)\"}"
            self._send_post_request(url: FeiTiAPI.host, data: bodyString, callback: {(data, response, error) -> Void in
                if let error = self._response_handler(data: data, response: response, error: error, success: {(jsonContent) -> Void in
                    if let token = jsonContent.value(forKey: "token") as? String, let user = jsonContent.value(forKey: "user") as? NSDictionary, let userData = UserData.parse(from: user) {
                        LocalStorage.CachedToken = token
                        LocalStorage.CachedUser = userData
                        DispatchQueue.main.async {
                            success()
                        }
                    }
                }) {
                    DispatchQueue.main.async {
                        failure(error)
                    }
                }
                
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            })
        }
        else {
            failure(FeiTiAPIError.LOCAL_TOKEN_INVALID)
        }
    }
    
    func _send_post_request(url: String, data: String, callback: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let status = Utility.NetworkStatus()
        if status == Utility.NetworkConnectionStatus.offline || Utility.NetworkConnectionStatus.unknown == status {
            callback(nil, nil, FeiTiAPIError.LOCAL_NETWORK_OFFLINE)
        }
        else if let uri = URL(string: url), let body = data.data(using: String.Encoding.utf8) {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            var request = URLRequest(url: uri)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            request.timeoutInterval = self.requestTimeout
            let task = session.dataTask(with: request, completionHandler: callback)
            task.resume()
        }
    }
    
    func _response_handler(data: Data?, response: URLResponse?, error: Error?, success: (_ data: NSDictionary) -> Void) -> FeiTiAPIError? {
        if error != nil {
            if let err = error as? FeiTiAPIError {
                return err
            }
            else {
                return FeiTiAPIError.HTTP_COMMON_UNKNOWN
            }
        }
        else if let data = data, let response = response, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary, jsonObject.count > 0, let status = jsonObject.value(forKey: "status") as? Int {
                    if status == 0 {
                        if let data = jsonObject.value(forKey: "data") as? NSDictionary {
                            success(data)
                            return nil
                        }
                    }
                    else {
                        return FeiTiAPIError(rawValue: status)
                    }
                }
            }
            catch {}
        }
        
        return FeiTiAPIError.HTTP_COMMON_INVALID_JSON_RESPONSE
    }
    
    func LoadClientCertificate() {
        if let cerPath = Bundle.main.path(forResource: "client", ofType: "cer"), let cerData = NSData(contentsOfFile: cerPath) {
            let unsafeData = cerData.bytes.assumingMemoryBound(to: UInt8.self)
            if let cerCFData = CFDataCreate(nil, unsafeData, cerData.length), let cerCAData = SecCertificateCreateWithData(nil, cerCFData) {
                let cerCAArrayData = NSArray(array: [cerCAData])
                self.clientCerData = cerCAArrayData
            }
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition,
        URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trust = challenge.protectionSpace.serverTrust, let clientCer = self.clientCerData {
                var err = SecTrustSetAnchorCertificates(trust, clientCer)
                if err == noErr {
                    var trustResult = SecTrustResultType.invalid
                    err = SecTrustEvaluate(trust, &trustResult)
                    if err == noErr {
                        let result = trustResult
                        if result == SecTrustResultType.proceed || result == SecTrustResultType.unspecified {
                            let credentials = URLCredential(trust: trust)
                            if let sender = challenge.sender {
                                sender.use(credentials, for: challenge)
                                completionHandler(URLSession.AuthChallengeDisposition.useCredential, credentials)
                                return
                            }
                        }
                    }
                }
            }
        }
        
        if let sender = challenge.sender {
            sender.cancel(challenge)
            completionHandler(URLSession.AuthChallengeDisposition.rejectProtectionSpace, nil)
        }
    }
}
