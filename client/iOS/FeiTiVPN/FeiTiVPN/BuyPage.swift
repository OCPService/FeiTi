//
//  BuyPage.swift
//  FeiTiVPN
//
//  Created by FeiTi on 05/12/2016.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import UIKit
import StoreKit
import GoogleMobileAds

class BuyPage: UITableViewController {
    var IsLoading = false
    var BuyItemId: String? = nil
    
    override func viewDidLoad() {
        IAP.Instance.ProductListReceived = self.IAPProductRecevied
        IAP.Instance.PurchaseSucceed = self.IAPPurchaseSucceed
        IAP.Instance.PurchaseRestored = self.IAPPurchaseRestored
        IAP.Instance.PurchaseFailed = self.IAPPurchaseFailed
        AdMob.Instance.InterAdReceived = self.AdReceived
        AdMob.Instance.InterAdClicked = self.AdClicked
        AdMob.Instance.InterAdDismissed = self.AdDismissed
        
        if let pids = LocalStorage.CachedIAPIDs, pids.count > 0 {
            var productIndentities = Set<String>()
            for pid in pids {
                productIndentities.insert(pid)
            }
            
            IAP.Instance.RequestProducts(productIds: productIndentities)
            self.IsLoading = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.UpdateCellsStatus()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let productIds = LocalStorage.CachedIAPIDs, productIds.count > 0 {
            return productIds.count + 1
        }

        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "buy_table_header".local()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellBuyItem", for: indexPath)
        if indexPath.row == 0 {
            cell.accessibilityHint = "free"
            if let headerView = cell.contentView.viewWithTag(200), let lbHeader = headerView as? UILabel, let detailView = cell.contentView.viewWithTag(400), let lbDetail = detailView as? UILabel {
                lbHeader.text = "buy_free_refresh_header".local()
                lbDetail.text = "buy_free_refresh_detail".local()
            }
        }
        else {
            if let pids = LocalStorage.CachedIAPIDs, pids.count > 0, (indexPath.row - 1) < pids.count {
                cell.accessibilityHint = pids[indexPath.row - 1]
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath), let hint = cell.accessibilityHint {
            self.tableView.isUserInteractionEnabled = false
            cell.isSelected = false
            self.BuyItemId = hint
            self.UpdateCellsStatus()

            if let nav = self.navigationController {
                nav.tabBarItem.badgeValue = nil
            }
            
            if hint == "free" {
                self.ShowAd()
            }
            else {
                var found = false
                for product in IAP.Instance.ProductList {
                    if hint == product.productIdentifier {
                        IAP.Instance.BuyProduct(product: product)
                        found = true
                        break
                    }
                }
                
                if !found {
                    self.FailureHandler(scenario: "buy_page_item_not_found", error: FeiTiAPIError.HTTP_COMMON_UNKNOWN)
                    self.tableView.isUserInteractionEnabled = true
                }
            }
        }
    }

    func UpdateCellsStatus() {
        if let user = LocalStorage.CachedUser {
            let cells = self.tableView.visibleCells
            for cell in cells {
                if let hint = cell.accessibilityHint, let headerView = cell.contentView.viewWithTag(200), let priceView = cell.contentView.viewWithTag(300), let detailView = cell.contentView.viewWithTag(400), let waitView = cell.contentView.viewWithTag(500) {
                    if hint == "free" {
                        headerView.isHidden = false
                        priceView.isHidden = false
                        detailView.isHidden = false
                        waitView.isHidden = true
                        cell.isUserInteractionEnabled = user.IsExpired
                        cell.backgroundColor = user.IsExpired ? UIColor.white : UIColor.lightGray
                    }
                    else {
                        headerView.isHidden = self.IsLoading
                        priceView.isHidden = self.IsLoading
                        detailView.isHidden = self.IsLoading
                        waitView.isHidden = !self.IsLoading
                        cell.isUserInteractionEnabled = !self.IsLoading
                        if self.IsLoading {
                            cell.backgroundColor = UIColor.white
                        }
                        else if hint == self.BuyItemId {
                            headerView.isHidden = true
                            priceView.isHidden = true
                            detailView.isHidden = true
                            waitView.isHidden = false
                            cell.isUserInteractionEnabled = false
                        }
                        else {
                            if user.IsExpired {
                                cell.backgroundColor = UIColor.white
                            }
                            else {
                                if user.Kind == UserData.TYPE_FREE {
                                    cell.isUserInteractionEnabled = true
                                    cell.backgroundColor = UIColor.white
                                }
                                else if user.Kind == UserData.TYPE_VIP {
                                    cell.isUserInteractionEnabled = false
                                    cell.backgroundColor = UIColor.lightGray
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func GetBuyingItemCell() -> UITableViewCell? {
        if let hint = self.BuyItemId {
            let cells = self.tableView.visibleCells
            for cell in cells {
                if hint == cell.accessibilityHint {
                    return cell
                }
            }
        }
        return nil
    }
    
    // Free Refresh
    func FreeRefresh() {
        FeiTiAPI.Instance.FreeRefresh(ad_clicked: false, ad_presented: false, success: {(hour, points) -> Void in
            self.ShowAlert(title: nil, message: String(format: "buy_free_refresh_success".local(), hour, points))
        }, failure: {(error) -> Void in
            self.FailureHandler(scenario: "buy_page_refresh_failure", error: FeiTiAPIError.HTTP_USER_FREE_REFRESH_FAILURE)
        }, completion: {() -> Void in
            self.BuyItemId = nil
            self.UpdateCellsStatus()
            self.tableView.isUserInteractionEnabled = true
        })
    }
    
    // Interstitial AD
    func ShowAd() {
        if let ad = LocalStorage.CachedAd, ad.DisplayInterAd {
            let adID = ad.InterAdID
            AdMob.Instance.RequestInterAd(adUnitID: adID)
        }
        else {
            self.FreeRefresh()
        }
    }
    
    // Interstitial AD callbacks
    func AdReceived(ad: GADInterstitial) {
        AdMob.Instance.PresentInterAd(rootViewController: self)
        FeiTiAPI.Instance.AdPresented(success: {() -> Void in}, failure: {(error) -> Void in})
    }
    
    func AdClicked(ad: GADInterstitial) {
        FeiTiAPI.Instance.AdClicked(success: {() -> Void in}, failure: {(error) -> Void in})
    }
    
    func AdDismissed(ad: GADInterstitial) {
        // print("AdDismissed")
        self.FreeRefresh()
    }
    
    // IAP callbacks
    func IAPProductRecevied(_ products: [SKProduct]) -> Void {
        self.IsLoading = false
        if products.count > 0 {
            let priceLocal = products[0].priceLocale
            let cells = self.tableView.visibleCells
            for product in products {
                for cell in cells {
                    if cell.accessibilityHint == "free" {
                        if let priceView = cell.contentView.viewWithTag(300), let lbPrice = priceView as? UILabel {
                            if let localPrice = Utility.NumberToCurrencyString(number: 0.0, local: priceLocal) {
                                lbPrice.text = localPrice.replacingOccurrences(of: "CN¥", with: "¥")
                            }
                            
                        }
                    }
                    else if cell.accessibilityHint == product.productIdentifier {
                        if let headerView = cell.contentView.viewWithTag(200), let lbHeader = headerView as? UILabel, let priceView = cell.contentView.viewWithTag(300), let lbPrice = priceView as? UILabel, let detailView = cell.contentView.viewWithTag(400), let lbDetail = detailView as? UILabel {
                            if let localPrice = Utility.NumberToCurrencyString(number: product.price, local: priceLocal) {
                                lbPrice.text = localPrice.replacingOccurrences(of: "CN¥", with: "¥")
                            }
                            
                            if let iaps = LocalStorage.CachedIAPs, iaps.count > 0 {
                                for iap in iaps {
                                    if iap.Id == product.productIdentifier {
                                        lbHeader.text = iap.Title
                                        lbDetail.text = iap.Description
                                        break
                                    }
                                }
                            }
                            else {
                                lbHeader.text = product.localizedTitle
                                lbDetail.text = product.localizedDescription
                            }
                            
                            lbHeader.sizeToFit()
                            lbDetail.sizeToFit()
                        }
                    }
                }
            }
            self.UpdateCellsStatus()
        }
    }
    
    func IAPPurchaseSucceed() -> Void {
        // print("Purchase Succeed!")
        // buy vip
        if let cell = self.GetBuyingItemCell(), let receipt = IAP.Instance.GetReceipt() {
            FeiTiAPI.Instance.Purchase(receipt: receipt, success: {() -> Void in
                if let headerView = cell.contentView.viewWithTag(200), let header = headerView as? UILabel, let title = header.text {
                    self.ShowAlert(title: nil, message: String(format: "buy_vip_success".local(), title))
                }
            }, failure: {(error) -> Void in
                self.FailureHandler(scenario: "bug_page_buy_failure", error: FeiTiAPIError.HTTP_USER_PURCHASE_FAILURE)
            }, completion: {() -> Void in
                self.BuyItemId = nil
                self.UpdateCellsStatus()
                self.tableView.isUserInteractionEnabled = true
            })
        }
        else {
            self.tableView.isUserInteractionEnabled = true
        }
    }
    
    func IAPPurchaseRestored() -> Void {
        // print("Purchase Restored!")
        self.BuyItemId = nil
        self.UpdateCellsStatus()
        self.tableView.isUserInteractionEnabled = true
    }
    
    func IAPPurchaseFailed() -> Void {
        // print("Purchase Failed!")
        self.BuyItemId = nil
        self.UpdateCellsStatus()
        self.tableView.isUserInteractionEnabled = true
    }
}

