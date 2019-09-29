//
//  AdMob.swift
//  FeiTiVPN
//
//  Created by FeiTi on 5/24/16.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import UIKit
import GoogleMobileAds

class AdMob: NSObject, GADInterstitialDelegate, GADBannerViewDelegate {
    static let TestDevices = [kGADSimulatorID, "c6b430b6465de2768144e537bd842329", "0b5506c1cd4ee407b312d2db8c4a4564"] as [Any]
    static let Instance = AdMob()
    static let InterAdID = "ca-app-pub-2274430690643715/2927118789"
    static let BannerAdID = "ca-app-pub-2274430690643715/1869187984"
    
    var interAd: GADInterstitial? = nil
    var InterAdReceiveFailed: ((_ ad: GADInterstitial, _ error: GADRequestError) -> Void)? = nil
    var InterAdReceived: ((_ ad: GADInterstitial) -> Void)? = nil
    var InterAdPresentFailed: ((_ ad: GADInterstitial) -> Void)? = nil
    var InterAdPresenting: ((_ ad: GADInterstitial) -> Void)? = nil
    var InterAdClicked: ((_ ad: GADInterstitial) -> Void)? = nil
    var InterAdDismissed: ((_ ad: GADInterstitial) -> Void)? = nil
    
    var BannerID: String? = nil
    var BannerContainerView: UIViewController? = nil
    var BannerAdReceived: ((_ adView: GADBannerView) -> Void)? = nil
    var BannerAdReceiveFailed: ((_ adView: GADBannerView, _ error: GADRequestError) -> Void)? = nil
    var BannerAdClicked: ((_ adView: GADBannerView) -> Void)? = nil
    var BannerAdDismissed: ((_ adView: GADBannerView) -> Void)? = nil
    
    // start Inter AD
    func RequestInterAd(adUnitID: String) {
        self.interAd = GADInterstitial(adUnitID: adUnitID)
        
        if let ad = self.interAd {
            ad.delegate = self
            let request = GADRequest()
            request.testDevices = AdMob.TestDevices
            ad.load(request)
        }
    }
    
    func PresentInterAd(rootViewController: UIViewController) {
        if let ad = self.interAd, ad.isReady {
            ad.present(fromRootViewController: rootViewController)
        }
    }
    // end Inter AD
    
    // start GADInterstitialDelegate
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        //print("Ad Receive Failed")
        if let handler = self.InterAdReceiveFailed {
            handler(ad, error)
        }
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        //print("Ad Received")
        self.interAd = ad
        if let handler = self.InterAdReceived {
            handler(ad)
        }
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
        //print("Ad Present Failed")
        if let handler = self.InterAdPresentFailed {
            handler(ad)
        }
    }
    
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        //print("Ad Presenting")
        if let handler = self.InterAdPresenting {
            handler(ad)
        }
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        //print("Ad Clicked")
        if let handler = self.InterAdClicked {
            handler(ad)
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        //print("Ad Dismissed")
        if let handler = self.InterAdDismissed {
            handler(ad)
        }
    }
    // end GADInterstitialDelegate
    
    
    // start Banner AD
    func LoadBannerAD(adUnitID: String, rootViewController: UIViewController) {
        self.BannerID = adUnitID
        self.BannerContainerView = rootViewController
        let bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        let request = GADRequest()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        bannerView.delegate = self
        rootViewController.view.addSubview(bannerView)
        request.testDevices = AdMob.TestDevices
        bannerView.load(request)
    }
    
    // end Banner AD
    
    // start GADBannerViewDelegate
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        //print("adView")
        if let handler = self.BannerAdReceiveFailed {
            handler(bannerView, error)
        }

        if let bannerId = self.BannerID, let container = self.BannerContainerView {
            self.LoadBannerAD(adUnitID: bannerId, rootViewController: container)
        }
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        //print("adViewDidReceived")
        if let handler = self.BannerAdReceived {
            handler(bannerView)
        }
    }
   
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        //print("adViewWillLeave")
        if let handler = self.BannerAdClicked {
            handler(bannerView)
        }
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        //print("adViewDidDismissed")
        if let handler = self.BannerAdDismissed {
            handler(bannerView)
        }
        self.BannerContainerView = nil
    }
    // end GADBannerViewDelegate
}
