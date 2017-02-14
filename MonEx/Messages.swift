//
//  Messages.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/13/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation

struct messages{
    
    var fromId: String
    var text: String
    var timeStamp: NSNumber
    var toId: String
    
    init?(_ dictionary: [String: Any]){
        
        guard let fromId = dictionary[Constants.messages.fromId] as? String else{
            print("fromId part failed")
            return nil
        }
        
        guard let text = dictionary[Constants.messages.text] as? String else{
            print("text part failed")
            return nil
        }
        
        guard let toId = dictionary[Constants.messages.toId] as? String else{
            print("toId failed")
            return nil 
        }
        guard let timeStamp = dictionary[Constants.messages.timeStamp] as? NSNumber else{
            print("timeStamp")
            return nil
        }
        
        self.fromId = fromId
        self.text = text
        self.timeStamp = timeStamp
        self.toId = toId
    }
}
