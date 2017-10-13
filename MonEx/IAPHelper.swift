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
    
    typealias ProductRequestCompletionHandler = ([SKProduct]?) -> ()
    private let productIdentifiers: Set<String>
    private var productRequest: SKProductsRequest?
    private var productRequestCompletionHandler: ProductRequestCompletionHandler?
    let rootReference = FIRDatabase.database().reference()
    let appUser = AppUser.sharedInstance
    
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
            }
        }
    }
    
    private func completeTransaction(_ transaction: SKPaymentTransaction){
        SKPaymentQueue.default().finishTransaction(transaction)
        //we have to update firebase to let it know that three credts need to be add it
        let path = "Users/\(appUser.firebaseId)/credits"
        let reference = rootReference.child(path)
        reference.runTransactionBlock { (currentData) -> FIRTransactionResult in
            if var credits = currentData.value as? Int {
                credits += 3
                currentData.value = credits
                
                return FIRTransactionResult.success(withValue: currentData)
            }
            return FIRTransactionResult.success(withValue: currentData)
        }
        
        
    }
    private func failedTransaction(_ transaction: SKPaymentTransaction){
        if (transaction.error as? SKError)?.code != SKError.paymentCancelled{
            print("transaction error \(transaction.error?.localizedDescription ?? "")")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}
