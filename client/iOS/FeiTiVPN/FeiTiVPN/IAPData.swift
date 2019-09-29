//
//  IAPData.swift
//  FeiTiVPN
//
//  Created by FeiTi on 11/02/2017.
//  Copyright © 2017 FeiTi. All rights reserved.
//

import Foundation

struct IAPData {
    let Id: String
    let Title: String
    let Description: String
    
    static func parse(from: String) -> [IAPData]? {
        var output: [IAPData]? = nil
        if let jsonData = from.data(using: String.Encoding.utf8) {
            do {
                if let iaps = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary], iaps.count > 0 {
                    output = parse(from: iaps)
                }
            }
            catch { }
        }
        
        return output
    }
    
    static func parse(from: [NSDictionary]) -> [IAPData]? {
        var output: [IAPData]? = nil
        if from.count > 0 {
            output = []
            for iap in from {
                if let iapData = parse(from: iap) {
                    output!.append(iapData)
                }
            }
        }
        return output
    }
    
    static func parse(from: NSDictionary) -> IAPData? {
        var output: IAPData? = nil
        if let id = from.value(forKey: "id") as? String, let title = from.value(forKey: "data_iap_title".local()) as? String, let description = from.value(forKey: "data_iap_description".local()) as? String {
            output = IAPData(Id: id, Title: title, Description: description)
        }
        return output
    }
}
