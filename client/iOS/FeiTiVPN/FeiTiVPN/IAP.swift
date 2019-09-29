//
//  IAP.swift
//  FeiTiVPN
//
//  Created by FeiTi on 6/6/16.
//  Copyright © 2016 FeiTi. All rights reserved.
//

import Foundation
import StoreKit

class IAP: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let PRODUCT_ID_VIP_ONE = "com.feiti.feitiservice.vip.one.month"
    static let PRODUCT_ID_VIP_THREE = "com.feiti.feitiservice.vip.three.month"
    static let PRODUCT_ID_VIP_SIX = "com.feiti.feitiservice.vip.six.month"
    static let PRODUCT_ID_VIP_TWELVE = "com.feiti.feitiservice.vip.twelve.month"
    static let ProductNames: Set<String> = [IAP.PRODUCT_ID_VIP_ONE, IAP.PRODUCT_ID_VIP_THREE, IAP.PRODUCT_ID_VIP_SIX, IAP.PRODUCT_ID_VIP_TWELVE]
    static let Instance = IAP()

    var ProductList = [SKProduct]()
    var ProductListReceived: ((_ products: [SKProduct]) -> Void)? = nil
    var PurchaseSucceed: (() -> Void)? = nil
    var PurchaseRestored: (() -> Void)? = nil
    var PurchaseFailed: (() -> Void)? = nil

    func RequestProducts(productIds: Set<String>) {
        let request = SKProductsRequest(productIdentifiers: productIds)
        request.delegate = self
        request.start()
    }
    
    func BuyProduct(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment)
    }
    
    func RestoreProduct() {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func GetReceipt() -> String? {
        if let receiptURL = Bundle.main.appStoreReceiptURL, let receiptData = NSData(contentsOf: receiptURL) {
            return receiptData.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithLineFeed)
        }
        return nil
    }

    // SKProductsRequestDelegate implement
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.ProductList = response.products
        
        if let handler = self.ProductListReceived {
            if self.ProductList.count > 0 {
                handler(self.ProductList)
            }
        }
    }
    
    // SKPaymentTransactionObserver implement
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case SKPaymentTransactionState.purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                if let handler = self.PurchaseSucceed {
                    handler()
                }
                break
            case SKPaymentTransactionState.restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                if let handler = self.PurchaseRestored {
                    handler()
                }
                break
 
            case SKPaymentTransactionState.failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                if let handler = self.PurchaseFailed {
                    handler()
                }
                break
            default:
                break
            }
        }
    }
}
