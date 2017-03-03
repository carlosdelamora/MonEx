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
        // Do any required interface initialization here.
        let urlString = "https://firebasestorage.googleapis.com/v0/b/monex-bc69a.appspot.com/o/ProfilePictures%2FD3YbHsorypR9EbMBJxBogtqpRfy1.jpg?alt=media&token=735e896d-0ec4-4049-b17f-a202b7fd31a6"
        downladImage(urlString: urlString)
    }
    
    func didReceive(_ notification: UNNotification) {
        self.nameLabel.text = notification.request.content.body
    }
    
    func downladImage(urlString: String){
        guard let url = URL(string: urlString) else{
            return
        }
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url){  data,response,error in
            let session = URLSession.shared
            //error code == -999 means the datatask was cancelled so we do not complain about it just return
            if let error = error as? NSError, error.code == -999 {
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







