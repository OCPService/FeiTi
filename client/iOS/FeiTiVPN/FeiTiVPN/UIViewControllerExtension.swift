//
//  ViewControllerExtension.swift
//  FeiTiVPN
//
//  Created by FeiTi on 5/14/16.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import UIKit

extension UIViewController {    
    func ShowAlert(title: String?, message: String?, style: UIAlertControllerStyle? = nil, actions: [UIAlertAction]? = nil, completion: (() -> Void)? = nil) -> Void {
        self.CancelAlert(completion: {() -> Void in
            let alert = UIAlertController(title: title, message: message, preferredStyle: style != nil ? style! : UIAlertControllerStyle.alert)
            
            if let actionCollection = actions {
                for action in actionCollection {
                    alert.addAction(action)
                }
            }
            else {
                let cancelAction = UIAlertAction(title: "common_ok".local(), style: UIAlertActionStyle.cancel, handler: nil)
                alert.addAction(cancelAction)
            }
            self.present(alert, animated: true, completion: completion)
        })
    }
    
    func CancelAlert(completion: (() -> Void)?) {
        DispatchQueue.main.async(execute: {() -> Void in
            if let controller = self.presentedViewController {
                if controller.isKind(of: UIAlertController.classForCoder()) {
                    controller.dismiss(animated: true, completion: completion)
                }
            }
            else if let block = completion {
                block()
            }
        })
    }
    
    func FailureHandler(scenario: String, error: FeiTiAPIError, completion: (() -> Void)? = nil) {
        switch error {
        case FeiTiAPIError.LOCAL_NETWORK_OFFLINE:
            if scenario == "signup_failure" || scenario == "signin_failure" {
                self.ShowAlert(title: nil, message: "error_network_unstable".local(), completion: {() -> Void in
                    Utility.StartMonitorNetworkStatus()
                })
            }
            else {
                self.ShowAlert(title: nil, message: "error_network_unstable".local(), completion: completion)
            }
        case FeiTiAPIError.HTTP_COMMON_TOKEN_TIMEOUT:
            self.ShowAlert(title: nil, message: "error_token_timeout".local(), completion: completion)
        case FeiTiAPIError.HTTP_USER_SIGN_UP_FAILURE:
            self.ShowAlert(title: nil, message: "error_sign_up_failed".local(), completion: completion)
        case FeiTiAPIError.HTTP_USER_SIGN_IN_FAILURE:
            self.ShowAlert(title: nil, message: "error_network_unstable".local(), completion: completion)
        case FeiTiAPIError.HTTP_USER_FREE_REFRESH_FAILURE:
            self.ShowAlert(title: nil, message: "error_free_refresh_failed".local(), completion: completion)
        case FeiTiAPIError.HTTP_USER_POINTS_TO_VIP_FAILURE:
            self.ShowAlert(title: nil, message: "error_redeem_vip_failed".local(), completion: completion)
        case FeiTiAPIError.HTTP_USER_PURCHASE_FAILURE:
            self.ShowAlert(title: nil, message: "error_buy_vip_failed".local(), completion: completion)
        case FeiTiAPIError.HTTP_USER_UPDATE_PASSWORD_FAILURE:
            self.ShowAlert(title: nil, message: "error_update_password_failed".local())
        case FeiTiAPIError.LOCAL_SAVE_FILE_FAILURE:
            self.ShowAlert(title: nil, message: "error_save_account_failed".local(), completion: completion)
        default:
            self.ShowAlert(title: nil, message: "error_network_unstable".local(), completion: completion)
        }
    }
}
