//
//  BrowseOffersViewCell.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/1/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Cosmos

class BrowseOffersViewCell: UITableViewCell {

    
    @IBOutlet weak var sellLabel: UILabel!
    
    @IBOutlet weak var buyLabel: UILabel!
    
    @IBOutlet weak var leftFlagImage: UIImageView!
    
    @IBOutlet weak var rightFlagImage: UIImageView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var profilePhotoImage: UIImageView!
    
    @IBOutlet weak var starsView: CosmosView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        sellLabel.text = "SELL"
        buyLabel.text = "BUY"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    
    
    
}
