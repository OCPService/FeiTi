//
//  ProfilePage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 13/01/2017.
//  Copyright © 2017 FeiTi. All rights reserved.
//

import UIKit

class ProfilePage: UIViewController {
    @IBOutlet weak var lbAccount: UILabel!
    @IBOutlet weak var lbType: UILabel!
    @IBOutlet weak var lbExpire: UILabel!
    @IBOutlet weak var lbPoints: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        if let user = LocalStorage.CachedUser {
            lbAccount.text = user.Account
            lbType.text = user.Kind == UserData.TYPE_VIP ? "profile_user_type_vip".local() : "profile_user_type_free".local()
            lbExpire.text = Utility.LocalDate(from: user.Expire)
            lbPoints.text = "\(user.Points)"
        }
        else {
            self.performSegue(withIdentifier: "ProfilePageToSignInPage", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func RetrieveUserCodeHandler(_ sender: UIButton) {
        if let user = LocalStorage.CachedUser {
            self.ShowAlert(title: nil, message: "profile_copy_code".local(), completion:{() -> Void in
                UIPasteboard.general.string = user.Hash
            })
        }
    }
    
}
