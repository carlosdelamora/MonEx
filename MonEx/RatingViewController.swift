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
        
        if let bidId = bidId{
            appUser.deleteInfoTerminated(bidId: bidId)
        }
        
        
        
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
        
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let stack = appDelegate.stack
            self.context = stack?.context
        }
        
        
        configureStorage()
        bidId = (acceptViewController?.offer?.bidId)!
        cosmosView.rating = 5
        cosmosView.settings.filledBorderColor = .yellow
        cosmosView.settings.emptyBorderColor = .yellow
        cosmosView.settings.fillMode = .precise
        cosmosView.settings.filledColor = .yellow
        view.backgroundColor = Constants.color.greyLogoColor
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bidId = (acceptViewController?.offer?.bidId)!
        let otherOffer = getOtherOffer(bidId: bidId!)
        
        guard let other = otherOffer else{
            //there is an error other offer is not in disk because the app was uninstalled perhaps? we thus complete this bid
            let pathToMyBids = "/Users/\(appUser.firebaseId)/Bid/\(bidId!)/offer/offerStatus" //update to completed
            self.rootReference.updateChildValues([pathToMyBids: Constants.offerStatus.complete])
            
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: {
                    self.acceptViewController?.dismissAcceptViewController(goToMyBids: true)
                })
            }

            return
        }
        
        imageUrlOfTheOther = other.imageUrlOfOther!
        firebaseIdOftheOther = other.firebaseIdOther!
        imageView.loadImage(url: imageUrlOfTheOther!, storageReference: storageReference, saveContext: nil, imageId: firebaseIdOftheOther!)
        label.text = String(format: NSLocalizedString("Give_name_a_rating", comment: "Give a rating: rating view controller. English format Give %@ a rating"), other.name!)
        
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
    

}
