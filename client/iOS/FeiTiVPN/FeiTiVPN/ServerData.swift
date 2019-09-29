//
//  Server.swift
//  FeiTiVPN
//
//  Created by FeiTi on 5/8/16.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation

struct ServerData {
    static let TYPE_FREE = 1
    static let TYPE_VIP = 8
    
    let IP: String?
    let Name: String
    let Kind: Int
    
    static func parse(from: String) -> [ServerData]? {
        var output: [ServerData]? = nil
        
        if let jsonData = from.data(using: String.Encoding.utf8) {
            do {
                if let servers = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary], servers.count > 0 {
                    output = parse(from: servers)
                    if var o = output {
                        o.sort(by: {(leftData, rightData) -> Bool in
                            let compare = leftData.Name.compare(rightData.Name)
                            if compare == ComparisonResult.orderedSame {
                                return leftData.Kind < rightData.Kind
                            }
                            return compare == ComparisonResult.orderedAscending
                        })
                    }
                }
            }
            catch {}
        }
        return output
    }
    
    static func parse(from: [NSDictionary]) -> [ServerData]? {
        var output: [ServerData]? = nil
        if from.count > 0 {
            output = []
            for serverData in from {
                if let server = parse(from: serverData) {
                    output!.append(server)
                }
            }
        }
        return output
    }
    
    static func parse(from: NSDictionary) -> ServerData? {
        var output: ServerData? = nil
        if let name = from.value(forKey: "data_server_name".local()) as? String, let kind = from.value(forKey: "kind") as? Int {
            if let ip = from.value(forKey: "ip") as? String {
                output = ServerData(IP: ip, Name: name, Kind: kind)
            }
            else {
                output = ServerData(IP: nil, Name: name, Kind: kind)
            }
        }
        return output
    }
}
