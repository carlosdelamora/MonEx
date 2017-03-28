//
//  RatingViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 3/21/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Cosmos
import FirebaseStorage
import CoreData
import Firebase

class RatingViewController: UIViewController {
    
    var storageReference: FIRStorageReference!
    var acceptViewController: AcceptOfferViewController?
    var imageUrlOfTheOther: String?
    var firebaseIdOftheOther: String?
    var context: NSManagedObjectContext? = nil
    let rootReference = FIRDatabase.database().reference()
    var bidId:String?
    let appUser = AppUser.sharedInstance
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var cosmosView: CosmosView!
    
    @IBAction func submitButton(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: {
                self.acceptViewController?.dismissAcceptViewController(goToMyBids: false)
            })
        }
        
        deleteInfo()
        
        rootReference.child("\(firebaseIdOftheOther!)").runTransactionBlock({(currentData: FIRMutableData) -> FIRTransactionResult in
        
    
            if var dictionary = currentData.value as? [String: Double]{
                
                if let numberOfTransactions = dictionary["numberOfTransactions"], let rating = dictionary["rating"]{

                    dictionary["rating"] = (rating*numberOfTransactions + self.cosmosView.rating)/(numberOfTransactions + 1)
                    dictionary["numberOfTransactions"] = 1 + numberOfTransactions
                    currentData.value = dictionary
                    
                    return FIRTransactionResult.success(withValue: currentData)
                }
            }
            return FIRTransactionResult.success(withValue: currentData)
            
        }){ (error, committed, snapshot) in
            
            if error != nil{
                print("error \(error.debugDescription)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        
        configureStorage()
        bidId = (acceptViewController?.offer?.bidId)!
        cosmosView.rating = 5
        cosmosView.settings.filledBorderColor = .yellow
        cosmosView.settings.emptyBorderColor = .yellow
        cosmosView.settings.fillMode = .precise
        cosmosView.settings.filledColor = .yellow
    }
    
    override func viewWillAppear(_ animated: Bool) {
        bidId = (acceptViewController?.offer?.bidId)!
        let otherOffer = getOtherOffer(bidId: bidId!)
        
        guard let other = otherOffer else{
            dismiss(animated: true, completion: nil)
            return
        }
        
        imageUrlOfTheOther = other.imageUrlOfOther!
        firebaseIdOftheOther = other.firebaseIdOther!
        imageView.loadImage(url: imageUrlOfTheOther!, storageReference: storageReference, saveContext: nil, imageId: firebaseIdOftheOther!)
        label.text = NSLocalizedString("Give \(other.name!) a rating", comment: "Give a rating: rating view controller")
        
    }

    
    
    func configureStorage(){
        storageReference = FIRStorage.storage().reference()
    }
    
    func getOtherOffer(bidId: String) -> OtherOffer?{
        
        var otherOffer: OtherOffer?
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "OtherOffer")
        let predicate = NSPredicate(format: "bidId = %@", argumentArray: [bidId])
        fetchRequest.predicate = predicate
        print("we fetch the request")
        context?.performAndWait {
            
            do{
                if let results = try self.context?.fetch(fetchRequest) as? [OtherOffer]{
                    otherOffer = results.first
                }
            }catch{
                fatalError("can not get the photos form core data")
            }
        }
        
        
        return otherOffer
    }
    
    
    func deleteInfo(){
        
        guard let bidId = self.bidId else{
            return 
        }
        
        rootReference.child("bidIdStatus/\(bidId)").observeSingleEvent(of: .value, with:{ (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else{
                return
            }
            
            
            guard let authorOfTheBid = dictionary[Constants.publicBidInfo.authorOfTheBid] as? String else{
                return
            }
            
            guard let otherUser = dictionary[Constants.publicBidInfo.otherUser] as? String else{
                return
            }
            
            guard let bidIdStatus = dictionary[Constants.publicBidInfo.status] as? String else{
                return
            }
            
            
            
            self.appUser.getOtherOffer(bidId: bidId){ otherOffer in
                
                guard let otherOffer = otherOffer else{
                    return
                }
                let pathForBidStatus = "/bidIdStatus/\(bidId)/\(Constants.publicBidInfo.status)" // set to Null if status is completed otherwise set to completed
                let pathForTranspose = "/transposeOfacceptedOffer/\(otherOffer.firebaseIdOther!)/\(bidId)"// set to Null if status is completed otherwise do nothing
                let pathForBidLocation = "/offerBidsLocation/\(bidId)/lastOfferInBid" // set to Null if status is completed otherwise do nothing
                let pathToMyBids = "/Users/\(self.appUser.firebaseId)/Bid/\(bidId)/offer/offerStatus" //update to completed
                //set to Null if status is completed otherwise do nothing we need to use the set function from firebase to aviod rejection atomic rejection by an empty offer or counteroffer
                let pathForCounterOffer = "/counterOffer/\(authorOfTheBid)/\(bidId)"//set to null
                //set to Null if status is completed otherwise do nothing we need to use the set function from firebase to aviod rejection atomic rejection by an empty offer or counteroffer
                let pathForCounterOfferOther = "/counterOffer/\(otherUser)/\(bidId)"
                
                
                if bidIdStatus == Constants.appUserBidStatus.complete{
                    
                    self.rootReference.updateChildValues([pathForBidStatus: NSNull(), pathForBidLocation: NSNull(), pathForTranspose: NSNull(), pathToMyBids: Constants.offerStatus.complete])
                    self.rootReference.updateChildValues([pathForCounterOffer: NSNull()])
                    self.rootReference.updateChildValues([pathForCounterOfferOther: NSNull()])
                    
                }else{
                    
                    self.rootReference.updateChildValues([pathForBidStatus: Constants.appUserBidStatus.complete, pathToMyBids: Constants.offerStatus.complete])
                }
            }
        })
    }

    

}
