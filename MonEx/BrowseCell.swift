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
        backgroundColor = Constants.color.greyLogoColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    

    @IBOutlet weak var distanceLabel: UILabel!
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
            //self.selectionStyle = .none
            //self.isUserInteractionEnabled = false
        }
        
        profileImage.image = UIImage(named: "Placeholder")
        let imageUrl = offer.imageUrl
        
        if let storageReference = storageReference{
            self.profileImage.loadImage(url: imageUrl, storageReference: storageReference, saveContext: nil, imageId: appUser.imageId)
        }
        
        
        if offer.offerStatus.rawValue == Constants.offerStatus.active{
            DispatchQueue.main.async {
                self.selectionStyle = .default
                self.isUserInteractionEnabled = true
            }
            
            let _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                DispatchQueue.main.async{
                    
                    UIView.animate(withDuration: 1, delay: 0, options: .allowUserInteraction, animations: {
                        if self.backgroundColor == .red {
                            self.backgroundColor = Constants.color.greyLogoColor
                        }else{
                            self.backgroundColor = .red
                        }
                    
                    }, completion: nil)
                    
                }
            })
        }
        
        if offer.offerStatus.rawValue == Constants.offerStatus.approved{
            DispatchQueue.main.async {
                self.selectionStyle = .default
                self.isUserInteractionEnabled = true
                UIView.animate(withDuration: 1, delay: 0, options: .allowUserInteraction, animations: {
                    self.backgroundColor = UIColor(red: 0, green: 0.6, blue: 0.4, alpha: 1)
                }, completion: nil)
                self.sellLabel.textColor = .black
                self.buyLabel.textColor = .black
                self.distanceLabel.textColor = .black
            }
        }

    }
    
    
}
