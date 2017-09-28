//
//  CachedRate.swift
//  MonEx
//
//  Created by Carlos De la mora on 9/27/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation


class CachedRate{
  
  var timeStamp: Date
  var sellBuyString: String
  var rate: Float
  
  init(timeStamp: Date, sellBuyString: String, rate:Float){
    
    self.timeStamp = timeStamp
    self.sellBuyString = sellBuyString
    self.rate = rate
  }
}
