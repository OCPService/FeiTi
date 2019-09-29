//
//  HomePage.swift
//  FeiTiVPN
//
//  Created by dl_support on 5/26/16.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import UIKit
import GoogleMobileAds

class HomePage: UITabBarController {
    var originTabBarPositionY: CGFloat? = nil
    var loadedBannerView: GADBannerView? = nil
    var isBannerPresented = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.originTabBarPositionY = self.tabBar.frame.origin.y
        AdMob.Instance.BannerAdReceived = self.BannerReceived
        AdMob.Instance.BannerAdReceiveFailed = restoreBannerPosition
        AdMob.Instance.BannerAdClicked = self.BannerClicked
        
        if let ad = LocalStorage.CachedAd, ad.Provider == "admob", ad.DisplayBanner {
            AdMob.Instance.LoadBannerAD(adUnitID: ad.BannerID, rootViewController: self)
        }
        
        /*
        var isNewServer = true
        var isNewNotification = true
        
        if let localHash = LocalStorage.ReadHashInfo() {
            if let serverHash = LocalStorage.CachedServerHash, let localServerHash = localHash.value(forKey: "server") as? String, localServerHash == serverHash {
                isNewServer = false
            }
            
            if let notificationHash = LocalStorage.CachedNotificationHash, let localNotificationHash = localHash.value(forKey: "notification") as? String, localNotificationHash == notificationHash {
                isNewNotification = false
            }
        }
        */
        
        self.SetBadge()
    }
    
    func SetBadge() {
        if let controllers = self.viewControllers {
            for controller in controllers {
                switch controller.tabBarItem.tag {
                case 100:
                    if let user = LocalStorage.CachedUser {
                        if user.IsExpired || LocalStorage.HasNewServer {
                            controller.tabBarItem.badgeValue = ""
                        }
                    }
                case 200:
                    if LocalStorage.HasNewNotification {
                        controller.tabBarItem.badgeValue = ""
                    }
                /*
                case 300:
                    if let user = LocalStorage.CachedUser, user.IsExpired {
                        controller.tabBarItem.badgeValue = ""
                    }
                */
                default:
                    break
                }
                
            }
        }
    }
    
    /*
    func SetBadge(newServer: Bool, newNotification: Bool) {
        if let controllers = self.viewControllers {
            for controller in controllers {
                switch controller.tabBarItem.tag {
                case 100:
                    if newServer {
                        controller.tabBarItem.badgeValue = ""
                    }
                case 200:
                    if let user = LocalStorage.CachedUser {
                        if user.IsExpired || newNotification {
                            controller.tabBarItem.badgeValue = ""
                        }
                    }
                /*
                case 300:
                    if let user = LocalStorage.CachedUser, user.IsExpired {
                        controller.tabBarItem.badgeValue = ""
                    }
                */
                default:
                    break
                }
                
            }
        }
    }
    */
    
    func BannerReceived(bannerView: GADBannerView) {
        if !self.isBannerPresented {
            self.isBannerPresented = true
            self.adjustBannerPosition(bannerView: bannerView)
            if let ad = LocalStorage.CachedAd, !ad.IsBannerClickable {
                bannerView.isUserInteractionEnabled = false
            }
            FeiTiAPI.Instance.AdPresented(success: {() -> Void in}, failure: {(error) -> Void in})
        }
    }
    
    func BannerClicked(bannerView: GADBannerView) {
        FeiTiAPI.Instance.AdClicked(success: {() -> Void in}, failure: {(error) -> Void in})
    }
    
    func adjustBannerPosition(bannerView: GADBannerView) {
        let innerHeight = self.view.frame.height
        let bannerY = innerHeight - bannerView.frame.height
        let tabY = bannerY - self.tabBar.frame.height
        self.tabBar.frame.origin.y = tabY
        bannerView.frame.origin.y = bannerY
    }
    
    func restoreBannerPosition(adView: GADBannerView) {
        if let tabY = self.originTabBarPositionY {
            self.tabBar.frame.origin.y = tabY
        }
        
        adView.frame.origin.y = 0
    }
    
    func restoreBannerPosition(adView: GADBannerView, error: GADRequestError) {
        self.restoreBannerPosition(adView: adView)
    }
}
