//
//  CustomNavigationBar.swift
//  MonEx
//
//  Created by Carlos De la mora on 10/1/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class CustomNavigationBar: UINavigationBar {

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var barPosition: UIBarPosition{
        return .topAttached
    }

}
