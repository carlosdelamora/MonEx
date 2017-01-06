//
//  Constants.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/4/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation


struct Constants{
    
    //MARK: currencies abbreviations
    struct currency{
       
        static let AUD = "AUD" // Australian Dollar
        static let CAD = "CAD" // Canadian Dollar 
        static let COP = "COP" // Colombian Peso
        static let EUR = "EUR" // Euro
        static let GBP = "GBP" //british pound
        static let MXN = "MXN" // Mexican peso
        static let USD = "USD" // USA Dollar 
        
    }
    
    //MARK: Yahoo client 
    //https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDMXN%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=
    struct YahooClient{
        static let APIScheme = "https"
        static let APIHost = "query.yahooapis.com"
        static let APIPath = "/v1/public/yql"

        static let queryMoney = "select * from yahoo.finance.xchange where pair in "//("USDMXN")"
    }
    
    
}
