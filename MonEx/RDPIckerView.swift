//
//  RDPIckerView.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class RDPIckerView: UIPickerView {
     //we create this class to change the color of the separators 
    @IBInspectable var selectorColor: UIColor? = Constants.color.greenLogoColor
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        guard let color = selectorColor else {
            return
        }
        
        if subview.bounds.height <= 1.0
        {
            subview.backgroundColor = color
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        guard let color = selectorColor else {
            return
        }
        
        for subview in subviews {
            if subview.bounds.height <= 1.0
            {
                subview.backgroundColor = color
            }
        }
    }

}
