//
//  BlackGradientView.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class BlackGradientView: UIView {

    override init(frame: CGRect){
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight] //we need this to cover the whole view after changing orientations.
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override func draw(_ rect: CGRect) {
        
        let components: [CGFloat] = [0,0,0,0.3,0,0,0,0.7]//0,0,0,0.3 is the grb alpha code, 0,0,0 means black color 0.3 is the alpha likewise the 0,0,0,0.7
        let locations: [CGFloat] = [0,1]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: 2)
        
        let x = bounds.midX
        let y = bounds.midY
        let centerPoint = CGPoint(x: x, y: y)
        let radius = max(x,y)
        
        let context = UIGraphicsGetCurrentContext()
        context?.drawRadialGradient(gradient!, startCenter: centerPoint, startRadius: 0, endCenter: centerPoint, endRadius: radius, options: .drawsAfterEndLocation)
        
    }


}
