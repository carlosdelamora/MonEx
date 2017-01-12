//
//  Offer.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/11/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation

class Offer{
    
    let sellQuantity: String
    let buyQuantity: String
    let sellCurrencyCode: String
    let buyCurrencyCode: String
    
    let yahooRate: String
    let yahooCurrencyRatio: String
    let rate : String
    let rateCurrencyRatio: String
    let active: Bool
    
    init?( _ dictionary: [String: String]){
        
        guard let sellQuantity = dictionary["sellQuantity"], let buyQuantity = dictionary["buyQuantity"], let sellCurrencyCode = dictionary["sellCurrencyCode"], let buyCurrencyCode = dictionary["buyCurrencyCode"]else{
            
            print("part 1 of initalizer failed")
            return nil
        }
        
        self.sellQuantity = sellQuantity
        self.buyQuantity = buyQuantity
        self.sellCurrencyCode = sellCurrencyCode
        self.buyCurrencyCode = buyCurrencyCode
        
        guard let yahooRate = dictionary["yahooRate"], let yahooCurrencyRatio = dictionary["yahooCurrencyRatio"],  let rate = dictionary["rate"], let rateCurrencyRatio = dictionary["rateCurrencyRatio"] else{
            
            print("part 2 of the initalizer failed")
            return nil
        }
        
        self.yahooCurrencyRatio = yahooCurrencyRatio
        self.yahooRate = yahooRate
        self.rate = rate
        self.rateCurrencyRatio = rateCurrencyRatio
        
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
