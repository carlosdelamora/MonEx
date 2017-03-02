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
        
    }
    
    func didReceive(_ notification: UNNotification) {
        self.nameLabel.text = notification.request.content.body
    }

}
