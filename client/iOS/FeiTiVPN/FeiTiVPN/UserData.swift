//
//  UserData.swift
//  FeiTiVPN
//
//  Created by FeiTi on 5/1/16.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation

struct UserData {
    static let TYPE_FREE = 1
    static let TYPE_VIP = 8
    
    let Account: String
    let Kind: Int
    let Expire: Date
    let Points: Int
    let Hash: String
    var IsExpired: Bool {
        get {
            return Date().compare(Expire) == ComparisonResult.orderedDescending
        }
    }
    
    static func parse(from: NSDictionary) -> UserData? {
        var output: UserData? = nil
        if let account = from.value(forKey: "account") as? String, let kind = from.value(forKey: "kind") as? Int, let expire_str = from.value(forKey: "expire") as? String, let expire = Utility.UTCDate(from: expire_str, format: nil), let points = from.value(forKey: "points") as? Int, let hash = from.value(forKey: "hash") as? String {
            output = UserData(Account: account, Kind: kind, Expire: expire, Points: points, Hash: hash)
        }
        return output
    }
    
    static func parse(from: String) -> UserData? {
        var output: UserData? = nil
        if let json = from.data(using: String.Encoding.utf8) {
            do {
                if let user = try JSONSerialization.jsonObject(with: json, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary, user.count > 0 {
                    output = parse(from: user)
                }
            }
            catch { }
        }
        return output
    }
}
