//
//  SettingsPage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 10/12/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import UIKit
import MessageUI

class SettingsPage: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var isNewNotificationPoint: UIImageView!
    @IBOutlet weak var SignOutColumn: UITableViewCell!
    
    let itunesUrl = "https://itunes.apple.com/app/fei-tivpn/id1122549971?mt=8"
    
    override func viewDidLoad() {
        if let nav = self.navigationController {
            self.isNewNotificationPoint.isHidden = nav.tabBarItem.badgeValue == nil
        }
        
        self.SignOutColumn.isHidden = !LocalStorage.CanManuallySignIn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                self.CheckNotifications()
            case 1:
                self.Comment()
            case 2:
                self.Share()
            case 3:
                self.SendingEmail()
            default:
                break
            }
        }
        else if indexPath.section == 2 && indexPath.row == 0 {
            LocalStorage.AutoSignIn = !LocalStorage.CanManuallySignIn
            self.performSegue(withIdentifier: "SignOut", sender: self)
        }
    }
    
    func CheckNotifications() {
        if let nav = self.navigationController, nav.tabBarItem.badgeValue != nil {
            if let hash = LocalStorage.CachedNotificationHash, LocalStorage.SaveHashInfo(name: "notification", value: hash) {
                nav.tabBarItem.badgeValue = nil
                self.isNewNotificationPoint.isHidden = true
            }
        }
    }
    
    func Comment() {
        if let uri = URL(string: itunesUrl) {
            UIApplication.shared.openURL(uri)
        }
    }
    
    func Share() {
        if let shareImage = UIImage(named: "ShareIcon"), let uri = URL(string: self.itunesUrl) {
            let shareView = UIActivityViewController(activityItems: [shareImage, "setting_share_title".local(), uri], applicationActivities: [])
            shareView.excludedActivityTypes = [UIActivityType.addToReadingList,
                                               UIActivityType.airDrop,
                                               UIActivityType.assignToContact,
                                               UIActivityType.copyToPasteboard,
                                               UIActivityType.openInIBooks,
                                               UIActivityType.saveToCameraRoll,
                                               UIActivityType.print]
            present(shareView, animated: true)
        }
    }
    
    func SendingEmail() {
        if let email = LocalStorage.CachedSupportEmail, let user = LocalStorage.CachedUser, MFMailComposeViewController.canSendMail() {
            let mailController = MFMailComposeViewController()
            mailController.mailComposeDelegate = self
            mailController.setSubject(String(format: "setting_mail_sent_subject".local(), user.Account))
            mailController.setToRecipients([email])
            mailController.setMessageBody("setting_mail_body".local(), isHTML: false)
            self.present(mailController, animated: true, completion: nil)
        }
        else {
            self.ShowAlert(title: nil, message: "setting_mail_unavailable".local())
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: {()->Void in
            switch result{
            case MFMailComposeResult.sent:
                self.ShowAlert(title: nil, message: "setting_mail_sent".local())
            case MFMailComposeResult.failed:
                self.ShowAlert(title: nil, message: "setting_mail_sent_failed".local())
            default:
                break
            }
        })
    }
}
