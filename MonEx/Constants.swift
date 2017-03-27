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
        static let firebaseId = "firebaseId"
        static let oneSignalId = "oneSignalId"
        static let offerStatus = "offerStatus"
    }
    
    struct offerStatus{
        static let nonActive = "nonActive"
        static let active = "active"
        static let counterOffer = "counterOffer"
        static let counterOfferApproved = "counterOfferApproved"
        static let approved = "approved"
        static let complete = "complete"
    }
    
    struct color{
        static let greenLogoColor = UIColor(displayP3Red: 191/255, green: 210/255, blue: 49/255, alpha: 1)
        static let greyLogoColor = UIColor(colorLiteralRed: 51/255, green: 51/255, blue: 50/255, alpha: 1)
        static let paternColor = UIColor(patternImage: UIImage(named: "Background")!)
        static let messagesBlue = UIColor(colorLiteralRed: 0, green: 137/255, blue: 249/255, alpha: 1)
    }
    
    struct offerBidLocation {
        static let offerBidsLocation = "offerBidsLocation"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let lastOfferInBid = "lastOfferInBid"
    }
    
    struct messages{
        static let fromId = "fromId"
        static let text = "text"
        static let timeStamp = "timeStamp"
        static let toId = "toId"
    }
    
    struct publicBidInfo{
        static let timeStamp = "timeStamp"
        static let status = "status"
        static let bidId = "bidId"
        static let authorOfTheBid = "authorOfTheBid"
        static let lastOneToWrite = "lastOneToWrite"
        static let otherUser = "otherUser"
    }
    
    struct notification{
        static let data = "data"
        static let imageUrl = "imageUrl"
        static let name = "name"
        static let distance = "distance"
        static let counterOfferPath = "counterOfferPath"
        static let bidId = "bidId"
        static let fiveMinutesNotification = "FiveMinNotification"
    }
    
    struct appUserBidStatus{
        static let moreThanFiveUserLastToWrite = "moreThanFiveUserLastToWrite"
        static let moreThanFiveOtherLastToWrite = "moreThanFiveOtherLastToWrite"
        static let lessThanFive = "lessThanFive"
        static let noBid = "noBid"
        static let nonActive = "nonActive"
        static let active = "active"
        static let counterOffer = "counterOffer"
        static let counterOfferApproved = "counterOfferApproved"
        static let approved = "approved"
        static let complete = "complete"
        
    }
    
    struct timeToRespond{
        static let timeToRespond = Double(30.0) // this is in seconds
    }
    
}
