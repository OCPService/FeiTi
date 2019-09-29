//
//  NotificationsPage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 27/01/2017.
//  Copyright © 2017 FeiTi. All rights reserved.
//

import UIKit

class NotificationsPage: UIViewController {
    @IBOutlet weak var webNotifications: UIWebView!
    
    override func viewDidLoad() {
        var content = ""
        if let notifications = LocalStorage.CachedNotifications {
            for notification in notifications {
                content += "<p><div class=\"title\">\(notification.Title)</div><div class=\"content\">\(notification.Content)</div><div class=\"date\">\(Utility.LocalDate(from: notification.Date))</div></p>"
            }
        }
        
        if content.characters.count > 0 {
            content = "<html><head><style type=\"text/css\">.title{color:blue;font-size:x-large;font-weight:bold} .content{color:black;font-size:medium;font-weight:normal} .date{color:grey;font-size:small;font-weight:normal}</style></head><body>\(content)</body></html>"
            self.webNotifications.loadHTMLString(content, baseURL: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
