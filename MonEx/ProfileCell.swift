//
//  ProfileCell.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/17/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import CoreGraphics

class ProfileCell: UICollectionViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileImage.layer.cornerRadius = profileImage.frame.width/2
        profileImage.layer.borderWidth = 2.0
        profileImage.layer.borderColor = UIColor.white.cgColor
        profileImage.clipsToBounds = true
        
        self.backgroundColor = Constants.color.greyLogoColor
        
        profileImage.image = UIImage(named: "photoPlaceholder")?.withRenderingMode(.alwaysTemplate)
        profileImage.image!.withRenderingMode(.alwaysTemplate)// needs to be set on storyboard otherwise does not work
        profileImage.tintColor = .white
    }
}
