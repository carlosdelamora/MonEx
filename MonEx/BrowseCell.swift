//
//  BrowseCell.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/1/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import FirebaseStorageUI

class BrowseCell: UITableViewCell {

    var offer: Offer? = nil
    let appUser = AppUser.sharedInstance
    var storageReference: FIRStorageReference?
    
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
    
    func configure(for offer: Offer){
        sellLabel.text = "SELL: \n \(offer.sellQuantity)"
        buyLabel.text = "BUY: \n \(offer.buyQuantity)"
        
        DispatchQueue.main.async {
            self.leftImageFlag.image = UIImage(named: offer.sellCurrencyCode + "small")
            self.rightImageFlag.image = UIImage(named: offer.buyCurrencyCode + "small")
        }
        
        profileImage.image = UIImage(named: "Placeholder")
        let imageUrl = offer.imageUrl
        
        if let storageReference = storageReference{
            self.profileImage.loadImage(url: imageUrl, storageReference: storageReference, saveContext: nil)
        }
    }
    
    
}
