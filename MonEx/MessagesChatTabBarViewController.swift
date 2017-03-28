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
        
        let frame = CGRect(x: tab.frame.origin.x, y: tab.frame.origin.y - 10, width: tab.frame.width, height: tab.frame.height)
        tab.frame = frame
        tab.backgroundColor = Constants.color.greyLogoColor
    }
    
    
    
    @IBOutlet weak var tab: UITabBar!
    
    
    
}

extension UITabBar{
    
    //this function together woth intinsicCpntentSize help us to create bigger buttons in the tab Bar for phones that use 3x i.e Iphone Plus 
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height += 5
        
        return sizeThatFits
    }
    
    
    open override var intrinsicContentSize: CGSize{
        var intrinsicSize = super.frame.size
        
        intrinsicSize.height += 5
        return intrinsicSize
    }
    
}
