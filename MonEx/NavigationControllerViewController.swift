//
//  NavigationControllerViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 3/3/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class NavigationControllerViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }

}
