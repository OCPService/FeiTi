//
//  AdData.swift
//  FeiTiVPN
//
//  Created by FeiTi on 29/11/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation

struct AdData {
    let Provider: String
    let DisplayBanner: Bool
    let IsBannerClickable: Bool
    let BannerID: String
    let DisplayInterAd: Bool
    let InterAdID: String
    
    static func parse(from: String) -> [AdData]? {
        var output: [AdData]? = nil
        if let jsonData = from.data(using: String.Encoding.utf8) {
            do {
                if let ads = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary], ads.count > 0 {
                    output = parse(from: ads)
                }
            }
            catch {}
        }
        return output
    }
    
    static func parse(from: [NSDictionary]) -> [AdData]? {
        var output: [AdData]? = nil
        if from.count > 0 {
            output = []
            for ad in from {
                if let adData = parse(from: ad) {
                    output!.append(adData)
                }
            }
        }
        return output
    }
    
    static func parse(from: NSDictionary) -> AdData? {
        var output: AdData? = nil
        if let provider = from.value(forKey: "provider") as? String, let displayBanner = from.value(forKey: "display_banner") as? Bool, let isBannerClickable = from.value(forKey: "is_banner_clickable") as? Bool, let bannerId = from.value(forKey: "banner_id") as? String, let displayInterAd = from.value(forKey: "display_inter_ad") as? Bool, let interAdId = from.value(forKey: "inter_ad_id") as? String {
            output = AdData(Provider: provider, DisplayBanner: displayBanner, IsBannerClickable: isBannerClickable, BannerID: bannerId, DisplayInterAd: displayInterAd, InterAdID: interAdId)
        }
        return output
    }
}
