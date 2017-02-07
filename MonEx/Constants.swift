//
//  Constants.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/4/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import UIKit

struct Constants{
    
    //MARK: currencies abbreviations
    struct currency{
        
        static let ARS = "ARS" // Argentinan Peso 
        static let AUD = "AUD" // Australian Dollar
        static let BRL = "BRL" // Brazilian Real
        static let CAD = "CAD" // Canadian Dollar 
        static let COP = "COP" // Colombian Peso
        static let EUR = "EUR" // Euro
        static let GBP = "GBP" //british pound
        static let MXN = "MXN" // Mexican peso
        static let USD = "USD" // USA Dollar 
        
    }
    
    //MARK: Yahoo client Example of how the query should look like
    //*https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDMXN%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=
    struct yahooClient{
        static let APIScheme = "https"
        static let APIHost = "query.yahooapis.com"
        static let APIPath = "/v1/public/yql"

        static let queryMoney = "select * from yahoo.finance.xchange where pair in "//("USDMXN")"
    }
    
    struct UI {
        static let LoginColorTop = UIColor(red: 0, green: 0, blue: 0 , alpha: 0).cgColor
        static let LoginColorBottom = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
    }
    
    struct profile{
        static let name = "name"
        static let email = "email"
        static let lastName = "lastName"
        static let phoneNumber = "phoneNumber"
        static let firebaseId = "firebaseId"
        static let imageUrl = "imageUrl"
        static let imageId = "imageId"
    }
    
    struct offer {
        static let buyCurrencyCode = "buyCurrencyCode"
        static let buyQuantity = "buyQuantity"
        static let dateCreated = "dateCreated"
        static let rateCurrencyRatio = "rateCurrencyRatio"
        static let sellCurrencyCode = "sellCurrencyCode"
        static let sellQuantity = "sellQuantity"
        static let timeStamp = "timeStamp"
        static let userRate = "userRate"
        static let yahooCurrencyRatio = "yahooCurrencyRatio"
        static let yahooRate = "yahooRate"
        static let isActive = "isActive"
        static let imageUrl = "imageUrl" //also in profile
        static let name = "name" //also in profile
    }
}
