//
//  YahooClient.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/4/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation


class YahooClient{
    
    private var dataTask: URLSessionDataTask? = nil
    typealias SearchComplete = (Bool) -> Void
    var rate: Float? = nil
    
    
    //https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDMXN%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=
    
  
    
    func yahooURLFromParameters(_ sellBuyString: String) -> URL {
        
        var parameters : [String: String ] = [:]
        let sqlQuery = Constants.YahooClient.queryMoney + "(\"\(sellBuyString)\")"
        
        parameters["q"] = sqlQuery
        parameters["format"] = "json"
        parameters["env"] = "store://datatables.org/alltableswithkeys"
        parameters["callback"] = ""
        
        var components = URLComponents()
        components.scheme = Constants.YahooClient.APIScheme
        components.host = Constants.YahooClient.APIHost
        components.path = Constants.YahooClient.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
       
        return components.url!
    }
    
    func performSearch(for url: URL,  completion: @escaping SearchComplete){
        
        //cancel the dataTask in case there is one already 
        dataTask?.cancel()
        var success = false
        
        let session = URLSession.shared
        dataTask = session.dataTask(with: url){ (data, response, error) in
            //error code == -999 means the datatask was cancelled so we do not complain about it just return
            if let error = error as? NSError, error.code == -999 {
                print("there was an error \(error)")
                return
            }else if let response = response as? HTTPURLResponse, 200 <= response.statusCode && response.statusCode <= 299{
                print("we do get a response")
                
                guard let data = data else{
                    return
                }
                
                guard let jsonDictionary = self.parseJsonData(data)else{
                    print("error with the parseJsonData")
                    return
                }
                let aRate = self.getRateFromDictionary(jsonDictionary)
                self.rate = self.getRateFromDictionary(jsonDictionary)
                
                success = true
                
                print("tic")
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
    
    // after parsing the Data we get a dictionary {"query":{"results":{"rate": {"Rate":"21.325"
    func getRateFromDictionary(_ dictionary : [String: Any])-> Float?{
        
        guard let query = dictionary["query"] as? [String: Any] else{
            print("query was not found")
            return nil
        }
        
        guard let results = query["results"] as? [String: Any] else{
            print("results was not found")
            return nil
        }
        
        guard let rate = results["rate"] as? [String: String] else{
            print("rate not found or cast failed")
            return nil
        }
        
        guard let Rate = rate["Rate"] else{
            print("Rate was not found")
            return nil
        }
        
        return Float(Rate)
        
    }
    
    
    
    
    
}
