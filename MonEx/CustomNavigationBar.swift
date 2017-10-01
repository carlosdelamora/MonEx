//
//  CustomNavigationBar.swift
//  MonEx
//
//  Created by Carlos De la mora on 10/1/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class CustomNavigationBar: UINavigationBar {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 64)
    }
    
    override var barPosition: UIBarPosition{
        return .topAttached
    }

}
