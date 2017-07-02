//
//  NotificationViewController.swift
//  ContentNotifications
//
//  Created by Carlos De la mora on 3/2/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI


class NotificationViewController: UIViewController, UNNotificationContentExtension {


    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func didReceive(_ notification: UNNotification) {
        
       
        
        if notification.request.identifier.contains("FiveMinNotification"){
            
            if let userInfo = notification.request.content.userInfo as? [String: Any]{
                guard let data = userInfo["data"] as? [String: String] else{
                    return
                }
                guard let name = data["name"] else{
                    return
                }
                self.nameLabel.text = name
                
                guard let imageUrl = data["imageUrl"] else{
                    return
                }
                downladImage(urlString: imageUrl)
                self.distanceLabel.text = ""
            }
            
        }else{
        
            guard let userInfo = notification.request.content.userInfo as? [String:Any] else{
                return
            }
            
            guard let custom = userInfo["custom"] as? [String: Any] else{
                return
            }
            
            guard let aDictionary = custom["a"] as? [String: String] else{
                print("no 'a' form notification")
                return 
            }
            
            
            guard let imageUrl = aDictionary["imageUrl"] else{
                print("no image url form notification")
                return
            }
            
            guard let name = aDictionary["name"] else {
                return
            }
            
            guard let distance = aDictionary["distance"] else{
                return
            }
            
            self.nameLabel.text = name
            self.distanceLabel.text = distance
            downladImage(urlString: imageUrl)
        }
        
        
    }
    
    func downladImage(urlString: String){
        guard let url = URL(string: urlString) else{
            return
        }
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url){  data,response,error in
            //error code == -999 means the datatask was cancelled so we do not complain about it just return
            if let error = error as NSError?, error.code == -999 {
                print("there was an error \(error)")
                return
            }else if let response = response as? HTTPURLResponse, 200 <= response.statusCode && response.statusCode <= 299{
                
                
                guard let data = data else{
                    return
                }
                
                guard let image = UIImage(data: data)else{
                    return
                }
                
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }
        dataTask.resume()
    }
}







