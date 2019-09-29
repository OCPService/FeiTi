//
//  ChangePasswordPage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 14/01/2017.
//  Copyright © 2017 FeiTi. All rights reserved.
//

import UIKit

class ChangePasswordPage: UIViewController {
    @IBOutlet weak var lbAccount: UILabel!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var waitUpdate: UIActivityIndicatorView!
    var localAccount: String? = nil
    var localPassword: String? = nil
    
    @IBAction func EndChangePassword(_ sender: UITextField) {
        sender.resignFirstResponder()
        if let password = sender.text, self.IsNewPasswordValid(password: password) {
            UpdateStatus(canUpdate: true, isUpdating: false)
        }
        else {
            UpdateStatus(canUpdate: false, isUpdating: false)
        }
    }
    
    @IBAction func EndOnExitChangePassword(_ sender: UITextField) {
        sender.resignFirstResponder()
        if let password = sender.text, self.IsNewPasswordValid(password: password) {
            UpdateStatus(canUpdate: true, isUpdating: false)
        }
        else {
            UpdateStatus(canUpdate: false, isUpdating: false)
        }
    }
    
    @IBAction func EditingPassword(_ sender: UITextField) {
        if let password = sender.text, self.IsNewPasswordValid(password: password) {
            UpdateStatus(canUpdate: true, isUpdating: false)
        }
        else {
            UpdateStatus(canUpdate: false, isUpdating: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let userInfo = LocalStorage.ReadUserInfo(), let account = userInfo.value(forKey: "account") as? String, let password = userInfo.value(forKey: "password") as? String {
            self.localAccount = account
            self.localPassword = password
            lbAccount.text = account
            self.UpdateStatus(canUpdate: false, isUpdating: false)
        }
        else {
            self.performSegue(withIdentifier: "ChangePasswordPageToSignInPage", sender: self)
        }
    }
    
    func IsNewPasswordValid(password: String) -> Bool {
        if let psw = localPassword, password.characters.count > 5, password != psw {
            return true
        }
        return false
    }
    
    func UpdateStatus(canUpdate: Bool, isUpdating: Bool) {
        waitUpdate.isHidden = !isUpdating
        btnUpdate.isEnabled = canUpdate
        btnUpdate.isUserInteractionEnabled = canUpdate
        
        if isUpdating {
            btnUpdate.setTitle("", for: btnUpdate.state)
        }
        else {
            btnUpdate.setTitle("psw_update".local(), for: btnUpdate.state)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func TapUpdate(_ sender: UIButton) {
        if let password = txtPassword.text, IsNewPasswordValid(password: password), let account = self.localAccount {
            self.UpdateStatus(canUpdate: false, isUpdating: true)
            FeiTiAPI.Instance.ChangePassword(password: password, success: {() -> Void in
                self.ShowAlert(title: nil, message: "psw_update_success".local(), completion: {() -> Void in
                    self.txtPassword.text = password
                    if LocalStorage.SaveUserInfo(account: account, password: password) {
                        print("success")
                    }
                })
            }, failure: {(error) -> Void in
                self.FailureHandler(scenario: "change_password_update_failure", error: FeiTiAPIError.HTTP_USER_UPDATE_PASSWORD_FAILURE)
            }, completion: {() -> Void in
                self.txtPassword.text = nil
                self.UpdateStatus(canUpdate: false, isUpdating: false)
            })
        }
        else {
            self.ShowAlert(title: nil, message: "psw_invalid".local())
        }
    }
    
    @IBAction func TapDisplayPassword(_ sender: UIButton) {
        txtPassword.isSecureTextEntry = !txtPassword.isSecureTextEntry
        if txtPassword.isSecureTextEntry {
            if let image = UIImage(named: "EyeClose") {
                sender.setImage(image, for: UIControlState.normal)
            }
        }
        else {
            if let image = UIImage(named: "EyeOpen") {
                sender.setImage(image, for: UIControlState.normal)
            }
        }
    }
    
}
