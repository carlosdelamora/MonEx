//
//  YahooClient.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/4/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation

//we will call it a yahoo client even thouhg is no longer yahoo powering this API

class YahooClient{
    
    private var dataTask: URLSessionDataTask? = nil
    typealias SearchComplete = (Bool) -> Void
    var rate: Float? = nil
    let APIKey = "5d00a51a10bc7bc07929b62a16683b0c"
    
    //http://apilayer.net/api/convert?access_key=5d00a51a10bc7bc07929b62a16683b0c&from=COP&to=USD&amount=1&format=1
    
  
    
  func yahooURLFromParameters(sell: String, buy: String) -> URL {
        
        var parameters : [String: String ] = [:]
    
        parameters["access_key"] = APIKey
        parameters["from"] = sell
        parameters["to"] = buy
        parameters["amount"] = "1"
        parameters["format"] = "1"
        
        var components = URLComponents()
        components.scheme = Constants.yahooClient.APIScheme
        components.host = Constants.yahooClient.APIHost
        components.path = Constants.yahooClient.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
       
        return components.url!
    }
    //@escaping because the completion is called after the function returns 
    func performSearch(for url: URL,  completion: @escaping SearchComplete){
        
        //cancel the dataTask in case there is one already 
        dataTask?.cancel()
        var success = false
        
        let session = URLSession.shared
        dataTask = session.dataTask(with: url){ (data, response, error) in
            //error code == -999 means the datatask was cancelled so we do not complain about it just return
            if let error = error as NSError?, error.code == -999 {
                print("there was an error \(error)")
                return
            }else if let response = response as? HTTPURLResponse, 200 <= response.statusCode && response.statusCode <= 299{
                
                
                guard let data = data else{
                    return
                }
                
                guard let jsonDictionary = self.parseJsonData(data)else{
                    print("error with the parseJsonData")
                    return
                }
              
                self.rate = self.getRateFromDictionary(jsonDictionary)
                //get rate from dictionary may return nil, so we need to check in not neel before claiming a success
                if let _ = self.rate{
                    success = true
                }
                
            }
            
            DispatchQueue.main.async {
                completion(success)
            }

        }
        dataTask?.resume()
        
    }
    
    // we use this function to obtain a dictionary from the data
    func parseJsonData(_ data: Data )-> [String: Any]?{
        
        do{
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }catch{
            print("Json Error \(error)")
            return nil
        }
    }
    
  /*after parsing the Data we get a dictionary {
  "success":true,
  "terms":"https:\/\/currencylayer.com\/terms",
  "privacy":"https:\/\/currencylayer.com\/privacy",
  "query":{
  "from":"COP",
  "to":"USD",
  "amount":1
  },
  "info":{
  "timestamp":1506490513,
  "quote":0.000342
  },
  "result":0.000342
}*/
    func getRateFromDictionary(_ dictionary : [String: Any])-> Float?{
        
        guard let result = dictionary["result"] as? Float else{
            print("query was not found")
            return nil
        }
        return result
    }
  
}












