//
//  Offer.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/11/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation


class Offer:NSObject{
    
    
    
    let quantitySell: String
    let quantityBuy: String
    let sellCurrencyCode: String
    let buyCurrencyCode: String
    
    let yahooRate: String
    let yahooCurrencyRatio: String
    let userRate : String
    let userRateCurrencyRatio: String
    let active: Bool
    let dateCreated: Date?
    let dateFormatter = DateFormatter()
    let timeStamp: String?
    
    init?( _ dictionary: [String: String]){
        
        guard let quantitySell = dictionary["quantitySell"], let quantityBuy = dictionary["quantityBuy"], let sellCurrencyCode = dictionary["sellCurrencyCode"], let buyCurrencyCode = dictionary["buyCurrencyCode"]else{
            
            print("part 1 of initalizer failed")
            return nil
        }
        
        self.quantitySell = quantitySell
        self.quantityBuy = quantityBuy
        self.sellCurrencyCode = sellCurrencyCode
        self.buyCurrencyCode = buyCurrencyCode
        
        guard let yahooRate = dictionary["yahooRate"], let yahooCurrencyRatio = dictionary["yahooCurrencyRatio"],  let userRate = dictionary["rate"], let userRateCurrencyRatio = dictionary["userRateCurrencyRatio"] else{
            
            print("part 2 of the initalizer failed")
            return nil
        }
        
        self.yahooCurrencyRatio = yahooCurrencyRatio
        self.yahooRate = yahooRate
        self.userRate = userRate
        self.userRateCurrencyRatio = userRateCurrencyRatio
        
        //self.dateFormatter = dateFormatter()
        
        guard let dateString = dictionary["dateCreated"], let date = dateFormatter.date(from: dateString), let timeStamp = dictionary["timeStamp"] else{
            return nil
        }
        
        self.dateCreated = date
        self.timeStamp = timeStamp
        
        guard let bool = dictionary["active"] else{
            return nil
        }
        
        if bool == "true"{
            self.active = true
        }else{
            self.active = false
        }
        
    }
}




