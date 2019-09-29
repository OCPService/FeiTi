//
//  SignInPage.swift
//  FeiTiVPN
//
//  Created by FeTi on 22/11/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import UIKit

class SignInPage: UIViewController {
    @IBOutlet weak var waitSubmitting: UIActivityIndicatorView!
    @IBOutlet weak var waitLoading: UIActivityIndicatorView!
    @IBOutlet weak var btnEye: UIButton!
    
    @IBOutlet weak var lbAccount: UILabel!
    @IBOutlet weak var lbPassword: UILabel!
    @IBOutlet weak var txtAccount: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnSignIn: UIButton!
    
    @IBAction func UITextFieldDoneEditOnExit(_ sender: UITextField) {
        sender.resignFirstResponder()
        let rect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.view.frame = rect
        if let text = sender.text, text.lengthOfBytes(using: String.Encoding.utf8) == 0, let id = sender.accessibilityIdentifier, let user = LocalStorage.ReadUserInfo() {
            if id == "InputAccount" {
                if let account = user.value(forKey: "account") as? String {
                    sender.text = account
                }
            }
            else if id == "InputPassword" {
                if let password = user.value(forKey: "password") as? String {
                    sender.text = password
                }
            }
        }
    }
    @IBAction func UITextFieldBeginEdit(_ sender: UITextField) {
        let frame = sender.frame
        let height = self.view.frame.size.height
        let offset = frame.origin.y + 85 - (height - 280.0)
        
        if offset > 0 {
            let width = self.view.frame.size.width
            let height = self.view.frame.size.height
            let rect = CGRect(x: 0.0, y: -offset, width: width, height: height)
            self.view.frame = rect
        }
    }
    @IBAction func UITextFieldEndEdit(_ sender: UITextField) {
        sender.resignFirstResponder()
        let rect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.view.frame = rect
        if let text = sender.text, text.lengthOfBytes(using: String.Encoding.utf8) == 0, let id = sender.accessibilityIdentifier, let user = LocalStorage.ReadUserInfo() {
            if id == "InputAccount" {
                if let account = user.value(forKey: "account") as? String {
                    sender.text = account
                }
            }
            else if id == "InputPassword" {
                if let password = user.value(forKey: "password") as? String {
                    sender.text = password
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(_NetworkStatusDidChanged), name: Utility.NetworkStatusNotificationName, object: nil)
        self.LoadUserInfo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        Utility.StopMonitorNetworkStatus()
    }
    
    @objc func _NetworkStatusDidChanged(notification: NSNotification) {
        if notification.name == Utility.NetworkStatusNotificationName {
            if let statusCollection = notification.userInfo as? [String: Utility.NetworkConnectionStatus], let status = statusCollection["status"], (status == Utility.NetworkConnectionStatus.wifi || status == Utility.NetworkConnectionStatus.cellular) {
                Utility.StopMonitorNetworkStatus()
                self.LoadUserInfo()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func SignInTap(_ sender: UIButton) {
        self.SignIn()
    }
    
    func LoadUserInfo() {
        self.UpdateControlStatus(isLoading: true, canInputAccount: false, canInputPassword: false, canSignIn: false, isSubmitting: false)
        
        if let userInfo = LocalStorage.ReadUserInfo(), userInfo.count > 0, let account =  userInfo.value(forKey: "account") as? String, account.characters.count > 0, let password = userInfo.value(forKey: "password") as? String, password.characters.count > 0 {
            self.txtAccount.text = account
            self.txtPassword.text = password
            
            self.UpdateControlStatus(isLoading: false, canInputAccount: true, canInputPassword: true, canSignIn: true, isSubmitting: false)
            if LocalStorage.AutoSignIn {
                self.SignIn()
            }
        }
        else {
            self.SignUp()
        }
    }
    
    func SignIn() {
        if let account = self.txtAccount.text, account.characters.count > 0, let password = self.txtPassword.text, password.characters.count > 0 {
            self.UpdateControlStatus(isLoading: false, canInputAccount: false, canInputPassword: false, canSignIn: false, isSubmitting: true)
            FeiTiAPI.Instance.SignIn(account: account, password: password, success: {() -> Void in
                if !LocalStorage.SaveUserInfo(account: account, password: password) {
                    self.FailureHandler(scenario: "save_user_data", error: FeiTiAPIError.LOCAL_COMMON_UNKNOWN, completion: {() -> Void in
                        self.performSegue(withIdentifier: "SignInPageToHomePage", sender: self)
                    })
                }
                else {
                    self.CancelAlert(completion: {() in
                        self.performSegue(withIdentifier: "SignInPageToHomePage", sender: self)
                    })
                }
            }, failure:{(error) -> Void in
                self.FailureHandler(scenario: "signin_failure", error: error, completion: {() -> Void in
                    self.UpdateControlStatus(isLoading: false, canInputAccount: true, canInputPassword: true, canSignIn: true, isSubmitting: false)
                    if LocalStorage.AutoSignIn {
                        self.SignIn()
                    }
                })
                /*
                if error == FeiTiAPIError.HTTP_USER_SIGN_IN_FAILURE {
                    let okAction = UIAlertAction(title: "common_ok".local(), style: UIAlertActionStyle.default)
                    
                    let restoreAction = UIAlertAction(title: "sign_in_restore".local(), style: UIAlertActionStyle.default, handler: {(action) in
                        if let user = LocalStorage.ReadUserInfo() {
                            if let username = user.value(forKey: "account") as? String {
                                self.txtAccount.text = username
                                if let psw = user.value(forKey: "password") as? String {
                                    self.txtPassword.text = psw
                                }
                            }
                            
                        }
                    })
                    
                    self.ShowAlert(title: nil, message: "error_sign_in_failed".local(), actions: [restoreAction, okAction], completion: {() in
                        self.UpdateControlStatus(isLoading: false, canInputAccount: true, canInputPassword: true, canSignIn: true, isSubmitting: false)
                    })
                }
                else {
                    self.FailureHandler(scenario: "signin_failure", error: error, completion: {() -> Void in
                        self.UpdateControlStatus(isLoading: false, canInputAccount: true, canInputPassword: true, canSignIn: true, isSubmitting: false)
                    })
                }
                */
            })
        }
    }

    
    func SignUp() {
        FeiTiAPI.Instance.SignUp(success: {(account, password) -> Void in
            self.txtAccount.text = account
            self.txtPassword.text = password
            if LocalStorage.SaveUserInfo(account: account, password: password) {
                self.UpdateControlStatus(isLoading: false, canInputAccount: true, canInputPassword: true, canSignIn: true, isSubmitting: false)
                self.SignIn()
            }
            else {
                self.FailureHandler(scenario: "save_user_data", error: FeiTiAPIError.LOCAL_SAVE_FILE_FAILURE)
            }
        }, failure: {(error) -> Void in
            self.FailureHandler(scenario: "signup_failure", error: error, completion: self.SignUp)
        })
    }

    // UI status change
    func UpdateControlStatus(isLoading: Bool, canInputAccount: Bool, canInputPassword: Bool, canSignIn: Bool, isSubmitting: Bool) {
        self.lbAccount.isHidden = !LocalStorage.CanManuallySignIn
        self.lbPassword.isHidden = !LocalStorage.CanManuallySignIn
        self.btnEye.isHidden = !LocalStorage.CanManuallySignIn
        self.txtAccount.isHidden = !LocalStorage.CanManuallySignIn
        self.txtPassword.isHidden = !LocalStorage.CanManuallySignIn
        self.btnSignIn.isHidden = !LocalStorage.CanManuallySignIn
        
        self.waitLoading.isHidden = !isLoading
        self.txtAccount.isEnabled = canInputAccount
        self.txtAccount.isUserInteractionEnabled = canInputAccount
        self.txtPassword.isEnabled = canInputPassword
        self.txtPassword.isUserInteractionEnabled = canInputPassword
        self.btnSignIn.isUserInteractionEnabled = canSignIn
        self.btnSignIn.isEnabled = canSignIn
        self.waitSubmitting.isHidden = !isSubmitting
        if isSubmitting {
            self.btnSignIn.setTitle("", for: UIControlState.normal)
        }
        else {
            self.btnSignIn.setTitle("sign_in_button".local(), for: UIControlState.normal)
        }
    }
    
    
    @IBAction func TapEye(_ sender: UIButton) {
        txtPassword.isSecureTextEntry = !txtPassword.isSecureTextEntry
        if txtPassword.isSecureTextEntry {
            if let image = UIImage(named: "EyeClose") {
                sender.setImage(image, for: UIControlState.normal)
            }
        }
        else {
            if let image = UIImage(named: "EyeOpenInWhite") {
                sender.setImage(image, for: UIControlState.normal)
            }
        }
    }
}

