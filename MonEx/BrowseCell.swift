//
//  BrowseCell.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/1/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class BrowseCell: UITableViewCell {

    var offer: Offer? = nil
    let appUser = AppUser.sharedInstance
   
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        sellLabel.text = NSLocalizedString("SELL", comment: "SELL: browse cell")
        buyLabel.text = NSLocalizedString("BUY", comment: "BUY:browse Cell")
        leftImageFlag.image = UIImage(named: "AUDsmall")
        rightImageFlag.image = UIImage(named: "AUDsmall")
        
    }
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    @IBOutlet weak var sellLabel: UILabel!
    @IBOutlet weak var buyLabel: UILabel!
    
   
    @IBOutlet weak var leftImageFlag: UIImageView!
    @IBOutlet weak var rightImageFlag: UIImageView!
    @IBOutlet weak var profileImage: UIImageView!
    
    
}
