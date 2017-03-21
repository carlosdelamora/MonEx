//
//  MessagesChatTabBarViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 3/20/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class MessagesChatTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tab.barTintColor = Constants.color.greyLogoColor
        //tab.backgroundColor = Constants.color.greyLogoColor
    }

    
    @IBOutlet weak var tab: UITabBar!
    
    
    
}
