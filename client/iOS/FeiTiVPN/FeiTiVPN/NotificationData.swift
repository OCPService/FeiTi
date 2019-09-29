//
//  NotificationData.swift
//  FeiTiVPN
//
//  Created by FeiTi on 29/11/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation

struct NotificationData {
    let Date: Date
    let Title: String
    let Content: String
    
    static func parse(from: String) -> [NotificationData]? {
        var output: [NotificationData]? = nil
        if let jsonData = from.data(using: String.Encoding.utf8) {
            do {
                if let notifications = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary], notifications.count > 0 {
                    output = parse(from: notifications)
                }
            }
            catch { }
        }

        return output
    }
    
    static func parse(from: [NSDictionary]) -> [NotificationData]? {
        var output: [NotificationData]? = nil
        if from.count > 0 {
            output = []
            for notification in from {
                if let notificationData = parse(from: notification) {
                    output!.append(notificationData)
                }
            }
        }
        return output
    }
    
    static func parse(from: NSDictionary) -> NotificationData? {
        var output: NotificationData? = nil
        if let dateData = from.value(forKey: "date") as? String, let date = Utility.UTCDate(from: dateData, format: nil), let title = from.value(forKey: "data_notification_title".local()) as? String, let content = from.value(forKey: "data_notification_content".local()) as? String {
            output = NotificationData(Date: date, Title: title, Content: content)
        }
        return output
    }
}
