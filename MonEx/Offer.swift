//
//  Offer.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/11/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation


class Offer:NSObject{
    
    
    
    let sellQuantity: String
    let buyQuantity: String
    let sellCurrencyCode: String
    let buyCurrencyCode: String
    let yahooRate: String
    let yahooCurrencyRatio: String
    let rateCurrencyRatio: String
    let userRate : String
    let isActive: Bool
    let imageUrl: String
    var latitude: Double?
    var longitude: Double?
    let name: String
    let dateCreated: Date?
    let dateFormatter = DateFormatter()
    let timeStamp: String?
    var firebaseId: String
    var bidId:String?
    var oneSignalId: String
    
    init?( _ dictionary: [String: String]){
        
        
        guard let sellQuantity = dictionary[Constants.offer.sellQuantity], let buyQuantity = dictionary[Constants.offer.buyQuantity], let sellCurrencyCode = dictionary[Constants.offer.sellCurrencyCode], let buyCurrencyCode = dictionary[Constants.offer.buyCurrencyCode] else{
            
            print("part 1 of initalizer failed")
            return nil
        }
        
        self.sellQuantity = sellQuantity
        self.buyQuantity = buyQuantity
        self.sellCurrencyCode = sellCurrencyCode
        self.buyCurrencyCode = buyCurrencyCode
        
        guard let yahooRate = dictionary[Constants.offer.yahooRate], let yahooCurrencyRatio = dictionary[Constants.offer.yahooCurrencyRatio],  let userRate = dictionary[Constants.offer.userRate] else{
            
            print("part 2 of the initalizer failed")
            return nil
        }
        
        self.yahooCurrencyRatio = yahooCurrencyRatio
        self.yahooRate = yahooRate
        self.userRate = userRate
        
        //set up dateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        
        guard let timeStamp = dictionary[Constants.offer.timeStamp] else {
            print("no time stamp")
            return nil
        }
        
        guard let timeStampDouble = Double(timeStamp) else{
            print("time stamp")
            return nil
        }
        
        let date = Date(timeIntervalSince1970:timeStampDouble)
          
        
        guard let rateCurrencyRatio = dictionary[Constants.offer.rateCurrencyRatio] else{
            print("no rate CurrencyRatio")
            return nil
        }
        
        guard let firebaseId = dictionary[Constants.offer.firebaseId], let oneSignalId = dictionary[Constants.offer.oneSignalId] else{
            print("no singnal id or no firebase id")
            return nil
        }
        
        self.firebaseId = firebaseId
        self.oneSignalId = oneSignalId
        self.rateCurrencyRatio = rateCurrencyRatio
        self.dateCreated = date
        self.timeStamp = timeStamp
        
        guard let bool = dictionary[Constants.offer.isActive], let imageUrl = dictionary[Constants.offer.imageUrl], let name = dictionary[Constants.offer.name] else{
            return nil
        }
        
        
        
        self.imageUrl = imageUrl
        self.name = name
        
        if bool == "true"{
            self.isActive = true
        }else{
            self.isActive = false
        }
        
    }
}




