//
//  IAPHelper.swift
//  MonEx
//
//  Created by Carlos De la mora on 10/11/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import StoreKit
import Firebase

class IAPHelper: NSObject{
    
    static let iAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    
    typealias ProductRequestCompletionHandler = ([SKProduct]?) -> ()
    private let productIdentifiers: Set<String>
    private var productRequest: SKProductsRequest?
    private var productRequestCompletionHandler: ProductRequestCompletionHandler?
    
    
    init(prodId: Set<String>){
        self.productIdentifiers = prodId
        super.init()
        SKPaymentQueue.default().add(self)
    }
}

extension IAPHelper{
    
    func requestProducts(completionHandler: @escaping ProductRequestCompletionHandler){
        productRequest?.cancel()
        productRequestCompletionHandler = completionHandler
    
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest?.delegate = self
        productRequest?.start()
    }
}

extension IAPHelper: SKProductsRequestDelegate{
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productRequestCompletionHandler?(response.products)
        productRequestCompletionHandler = nil
        productRequest = nil
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Error:\(error.localizedDescription)")
        productRequestCompletionHandler?(nil)
        productRequestCompletionHandler = nil
        productRequest = nil
    }
    
    func buyAProduct(product:SKProduct){
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
}

extension IAPHelper: SKPaymentTransactionObserver{
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transction in transactions{
            switch transction.transactionState{
            case .purchased:
                completeTransaction(transction)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            case .failed:
                failedTransaction(transction)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            case .deferred:
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                print("what is this deferred")
            case .restored:
                print("what is this")
            case .purchasing:
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                print("purchasing")
            default:
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                print("case not handled \(transction.transactionState)")
            }
        }
    }
    
    private func completeTransaction(_ transaction: SKPaymentTransaction){
        deliverNotification(forIdendifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        //we have to update firebase to let it know that three credts need to be add it
        
    }
    private func failedTransaction(_ transaction: SKPaymentTransaction){
        if (transaction.error as? SKError)?.code != SKError.paymentCancelled{
            print("transaction error \(transaction.error?.localizedDescription ?? "")")
        }
    }
    
    private func deliverNotification(forIdendifier identifier: String?){
        guard let identifier = identifier else { return }
        print(identifier)
        NotificationCenter.default.post(name: Notification.Name(type(of:self).iAPHelperPurchaseNotification), object: identifier)
    }
}
