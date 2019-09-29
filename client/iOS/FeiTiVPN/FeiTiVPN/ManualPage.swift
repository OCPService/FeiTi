//
//  ManualPage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 09/12/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import UIKit

class ManualPage: UITableViewController {
    
    @IBOutlet weak var cellQnA: UITableViewCell!
    @IBOutlet weak var lbQnA: UILabel!
    
    override func viewDidLoad() {
        self.cellQnA.selectionStyle = UITableViewCellSelectionStyle.none
        if let filePath = Bundle.main.path(forResource: "manual_qna".local(), ofType: nil) {
            let fileUrl = URL(fileURLWithPath: filePath)
            do {
                self.lbQnA.text = try String(contentsOf: fileUrl, encoding: String.Encoding.utf8)
                self.lbQnA.sizeToFit()
            }
            catch {}
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section > 0 && indexPath.row == 0 {
            return self.lbQnA.frame.height
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                ManualDetailPage.detailTag = "connect"
            case 1:
                ManualDetailPage.detailTag = "points"
            default:
                break
            }
        }
    }
}
