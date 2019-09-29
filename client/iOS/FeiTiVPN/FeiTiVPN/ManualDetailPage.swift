//
//  ManualDetailPage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 01/02/2017.
//  Copyright © 2017 FeiTi. All rights reserved.
//

import UIKit

class ManualDetailPage: UIViewController {
    static var detailTag: String? = nil
    @IBOutlet weak var manualTitle: UINavigationItem!
    @IBOutlet weak var manualWebContent: UIWebView!
    
    override func viewWillAppear(_ animated: Bool) {
        if let tag = ManualDetailPage.detailTag {
            var filename: String? = nil
            switch tag {
            case "connect":
                manualTitle.title = "manual_connect_title".local()
                filename = "manual_connect".local()
            case "points":
                manualTitle.title = "manual_points_title".local()
                filename = "manual_points".local()
            default:
                break
            }
            
            if let file = filename, let content = LocalStorage.ReadManualFile(filename: file) {
                manualWebContent.load(content, mimeType: "text/html", textEncodingName: "utf-8", baseURL: URL(fileURLWithPath: ""))
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
