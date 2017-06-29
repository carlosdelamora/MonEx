//
//  LoadingCell.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/22/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import UIKit

class LoadingCell: UITableViewCell{
    
    let label: UILabel = {
        let aLabel = UILabel()
        aLabel.textColor = Constants.color.greenLogoColor
        aLabel.text = NSLocalizedString("loading...", comment: "loading...")
        return aLabel
    }()
    
    let activityIndicatior : UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.tag = 100
        activityIndicator.color = Constants.color.greenLogoColor
        return activityIndicator
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
        self.selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //setUpViews()
    }
    
    func setUpViews(){
        self.addSubview(label)
        self.addSubview(activityIndicatior)
        label.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatior.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .black
        label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: activityIndicatior.leftAnchor).isActive = true
        label.heightAnchor.constraint(equalToConstant: 30).isActive = true
        activityIndicatior.heightAnchor.constraint(equalToConstant: 30).isActive = true
        activityIndicatior.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true 
    }
}
