//
//  PublicBidInfo.swift
//  MonEx
//
//  Created by Carlos De la mora on 3/23/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation

class PublicBidInfo{
    
    var timeStamp: Double
    var status: String
    var bidId: String
    var authorOfTheBid: String
    var count: Int = 0
    var otherUser: String
    
    init?(dictionary: [String: Any]){
        
        guard let timeStamp = dictionary[Constants.publicBidInfo.timeStamp] as? Double, let status = dictionary[Constants.publicBidInfo.status] as? String else{
            return nil
        }
        
        guard let bidId = dictionary[Constants.publicBidInfo.bidId] as? String, let authorOfTheBid = dictionary[Constants.publicBidInfo.authorOfTheBid] as? String else{
            return nil
        }
 
        guard let count = dictionary[Constants.publicBidInfo.count] as? Int, let otherUser = dictionary[Constants.publicBidInfo.otherUser] as? String else{
            return nil
        }
        
        self.timeStamp = timeStamp
        self.status = status
        self.bidId = bidId
        self.authorOfTheBid = authorOfTheBid
        self.count = count
        self.otherUser = otherUser
    }
    
}
