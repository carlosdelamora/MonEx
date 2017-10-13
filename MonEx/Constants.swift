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
    //*http://apilayer.net/api/convert?access_key=5d00a51a10bc7bc07929b62a16683b0c&from=COP&to=USD&amount=1&format=1
    struct yahooClient{
        static let APIScheme = "https"
        static let APIHost = "apilayer.net"
        static let APIPath = "/api/convert"
        static let APILivePath = "/api/live"
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
        static let latitude = "latitude"
        static let longitude = "longitude"
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
        static let halfComplete = "halfComplete"
        static let complete = "complete"
    }
    
    struct color{
        static let greenLogoColor = UIColor(red: 191/255, green: 210/255, blue: 49/255, alpha: 1)
        static let greyLogoColor = UIColor(red: 51/255, green: 51/255, blue: 50/255, alpha: 1)
        static let paternColor = UIColor(patternImage: UIImage(named: "Background")!)
        static let messagesBlue = UIColor(red: 0, green: 137/255, blue: 249/255, alpha: 1)
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
        static let halfComplete = "halfComplete"
        static let complete = "complete"
        
    }
    
    struct timeToRespond{
        static let timeToRespond = Double(5*60.0) // this is in seconds
    }
    
}
