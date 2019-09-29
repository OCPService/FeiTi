//
//  PointsToVipPage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 27/01/2017.
//  Copyright © 2017 FeiTi. All rights reserved.
//

import UIKit

class PointsToVipPage: UITableViewController {
    override func viewDidAppear(_ animated: Bool) {
        self.UpdateStatus()
    }
    
    func UpdateStatus() {
        if let user = LocalStorage.CachedUser, (user.Kind == UserData.TYPE_FREE || user.IsExpired) {
            for cell in self.tableView.visibleCells {
                if let waiter = cell.contentView.viewWithTag(300) as? UIActivityIndicatorView {
                    waiter.isHidden = true
                }
                
                if user.Points >= cell.tag {
                    cell.isUserInteractionEnabled = true
                    cell.backgroundColor = UIColor.white
                }
                else {
                    cell.isUserInteractionEnabled = false
                    cell.backgroundColor = UIColor.lightGray
                }
            }
        }
        else {
            for cell in self.tableView.visibleCells {
                cell.isUserInteractionEnabled = false
                cell.backgroundColor = UIColor.lightGray
                if let waiter = cell.contentView.viewWithTag(300) as? UIActivityIndicatorView {
                    waiter.isHidden = true
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath), let header = cell.contentView.viewWithTag(100) as? UILabel, let price = cell.contentView.viewWithTag(200) as? UILabel, let waiter = cell.contentView.viewWithTag(300) as? UIActivityIndicatorView {
            let days = cell.tag == 1000 ? "7" : (cell.tag == 2000 ? "15" : (cell.tag == 3000 ? "30" : "?"))
            let cancelAction = UIAlertAction(title: "common_no".local(), style: UIAlertActionStyle.cancel, handler: nil)
            let okAction = UIAlertAction(title: "common_yes".local(), style: UIAlertActionStyle.default, handler: {(action) -> Void in
                self.tableView.isUserInteractionEnabled = false
                header.isHidden = true
                price.isHidden = true
                waiter.isHidden = false
                
                FeiTiAPI.Instance.Point2VIP(points: cell.tag, success: {() -> Void in
                    self.ShowAlert(title: nil, message: String(format: "redeem_success".local(), days))
                }, failure: {(error) -> Void in
                    self.FailureHandler(scenario: "points2vip", error: error)
                }, completion: {() -> Void in
                    self.tableView.isUserInteractionEnabled = true
                    header.isHidden = false
                    price.isHidden = false
                    waiter.isHidden = true
                    cell.isSelected = false
                    self.UpdateStatus()
                })
            })
            self.ShowAlert(title: nil, message: String(format: "redeem_dialog".local(), days, cell.tag), style: nil, actions: [cancelAction, okAction], completion: nil)
        }
    }
    
}
