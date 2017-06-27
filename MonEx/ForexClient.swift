//
//  ForexClient.swift
//  MonEx
//
//  Created by Carlos De la mora on 6/27/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation


//
//  YahooClient.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/4/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation


class forexClient{
    
    private var dataTask: URLSessionDataTask? = nil
    typealias SearchComplete = (Bool) -> Void
    var rate: Float? = nil
    var same: Bool = false
    
    //https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDMXN%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=
    
    
    //we change our API service from yahoo finance to forex
    //https://forex.1forge.com/1.0.1/convert?from=USD&to=MXN&quantity=1
    
    func forexURLFromParameters(from sell:String, to buy:String) -> URL {
        
        same = (sell == buy)
        var parameters : [String: String ] = [:]
        //let sqlQuery = Constants.yahooClient.queryMoney + "(\"\(sellBuyString)\")"
        
        parameters["from"] = sell
        parameters["to"] = buy
        parameters["quantity"] = "1"
        
        
        var components = URLComponents()
        components.scheme = Constants.forexClient.APIScheme
        components.host = Constants.forexClient.APIHost
        components.path = Constants.forexClient.APIPath
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
            if let error = error as? NSError, error.code == -999 {
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
                success = true
                
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
    
    // after parsing the Data we get a dictionary {"value":17.91436,"text":"1 USD is worth 17.91436 MXN","timestamp":1498519770}
    func getRateFromDictionary(_ dictionary : [String: Any])-> Float?{
        
        //if is the same symbol return 1
        if same{
            return 1.0
        }
        
        guard let value = dictionary["value"] as? Float else{
            print("query was not found")
            return nil
        }
        
        return Float(value)
        
    }
    
}
