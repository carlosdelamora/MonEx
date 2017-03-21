//
//  BrowseCell.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/1/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import FirebaseStorageUI
import MapKit
import Cosmos

class BrowseCell: UITableViewCell {

    var offer: Offer? = nil
    let appUser = AppUser.sharedInstance
    var storageReference: FIRStorageReference?
    var timer: Timer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        sellLabel.text = NSLocalizedString("SELL", comment: "SELL: browse cell")
        buyLabel.text = NSLocalizedString("BUY", comment: "BUY:browse Cell")
        leftImageFlag.image = UIImage(named: "AUDsmall")
        rightImageFlag.image = UIImage(named: "AUDsmall")
        backgroundColor = UIColor.lightGray//Constants.color.greyLogoColor
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
    @IBOutlet weak var cosmosView: CosmosView!
 
    
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
            //this way we do not run the time schedule more than once
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                DispatchQueue.main.async{
                    
                    UIView.animate(withDuration: 1, delay: 0, options: .allowUserInteraction, animations: {
                        if self.backgroundColor == .red {
                            self.backgroundColor = .lightGray//Constants.color.greyLogoColor
                        }else{
                            self.backgroundColor = .red
                        }
                    
                    }, completion: nil)
                    
                }
            })
        }
        
        if offer.offerStatus.rawValue == Constants.offerStatus.approved || offer.offerStatus.rawValue == Constants.offerStatus.counterOfferApproved{
            //if the function in timer was already on we prevent to change color form green to red
            timer?.invalidate()
            DispatchQueue.main.async {
                self.selectionStyle = .default
                self.isUserInteractionEnabled = true
                UIView.animate(withDuration: 1, delay: 0, options: .allowUserInteraction, animations: {
                    self.backgroundColor = Constants.color.greenLogoColor
                }, completion: nil)
            }
        }
        
        if offer.offerStatus.rawValue == Constants.offerStatus.counterOffer{
            
            DispatchQueue.main.async {
                self.selectionStyle = .default
                self.isUserInteractionEnabled = true
            }
            //this way we do not run the time schedule more than once
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                DispatchQueue.main.async{
                    
                    UIView.animate(withDuration: 1, delay: 0, options: .allowUserInteraction, animations: {
                        if self.backgroundColor == .yellow {
                            self.backgroundColor = .lightGray//Constants.color.greyLogoColor
                        }else{
                            self.backgroundColor = .yellow
                        }
                    }, completion: nil)
                
                }
            })
        }

        guard let latitude = offer.latitude, let longitude = offer.longitude else{
            distanceLabel.text = "?"
            return
        }
            
        let sellerLocation = CLLocation(latitude: latitude , longitude: longitude)
        guard let location = appUser.location else{
            distanceLabel.text = "?"
            return
        }
        let distance = sellerLocation.distance(from: location)
        let distanceFormatter = MKDistanceFormatter()
        //distanceLabel.text = distanceFormatter.string(fromDistance: distance)
        
        //set up dateFormatter()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        if let interval = Double(offer.timeStamp!){
            let date = Date(timeIntervalSince1970: interval)
            distanceLabel.text = dateFormatter.string(from: date) + "\n" + distanceFormatter.string(fromDistance: distance)
            
        }

        
        appUser.getRating(firebaseId: offer.firebaseId){ rating in
          
            if rating < 0{
                DispatchQueue.main.async {
                    self.cosmosView.rating = 1
                    self.cosmosView.settings.totalStars = 1
                    self.cosmosView.settings.filledColor = .lightGray
                    self.cosmosView.settings.filledBorderColor = Constants.color.greenLogoColor
                    self.cosmosView.text = NSLocalizedString("Not rated", comment: "Not rated")
                }
                
            }else{
                DispatchQueue.main.async {
                    self.cosmosView.rating = rating
                    self.cosmosView.settings.fillMode = .precise
                    self.cosmosView.settings.filledColor = .yellow
                    self.cosmosView.settings.emptyBorderColor = .yellow
                    self.cosmosView.settings.filledBorderColor = .yellow
                    self.cosmosView.tintColor = .blue
                    self.cosmosView.text = "\(rating)"
                }
            }
        }
    }
    
    
}
