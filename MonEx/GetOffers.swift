//
//  GetOffers.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/26/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import Firebase

class GetOffers{
    
    var arrayOfOffers = [Offer]() {
        didSet{
            print("\(arrayOfOffers.count)")
        }
    }
    let appUser = AppUser.sharedInstance
    var transposeOffer : Offer?
    var currentStatus: status = .notsearchedYet
    
    enum status{
        case notsearchedYet
        case loading
        case nothingFound
        case results([Offer])
    }

    //we ise this in the .browseOffers table, we get this from the path offerBidsLocation/$bidId/lastOfferInBid
    func getArraysOfOffers(path: String, completion: @escaping ()-> Void) -> FIRDatabaseHandle{
        //make sure that when we start the computation we have nothing in the array of offers
        let rootReference = FIRDatabase.database().reference()
        let reference = rootReference.child(path)
        currentStatus = .loading
        let _refHandle = reference.observe(.value, with:{ snapshot in
            
             //make sure that when we start the computation we have nothing in the array of offers
            self.arrayOfOffers = [Offer]()
            guard let value = snapshot.value as? [String: Any] else{
                self.currentStatus = .nothingFound
                completion()
                return
            }
            
            sleep(UInt32(1))
            for bidId in value.keys{
                
                //the node is a dictionary of the bidId key and contains the keys lasOfferInBid, latitude, longitude, userFirebaseId the latter is the id for the author of the bid.
                if let node = value[bidId] as? [String: Any], let dictionary = node[Constants.offerBidLocation.lastOfferInBid] as? [String: String], let offer = Offer(dictionary) {
                    
                    
                    offer.bidId = bidId
                    
                    if let latitude = node[Constants.offerBidLocation.latitude] as? Double, let longitude = node[Constants.offerBidLocation.longitude] as? Double {
                        offer.latitude = latitude
                        offer.longitude = longitude
                    }
                     
                    //in order to display the offer, has to be done by somone else and not be active.
                    if offer.firebaseId != self.appUser.firebaseId && offer.offerStatus.rawValue == Constants.offerStatus.nonActive{
                            self.arrayOfOffers.append(offer)
                    }
                }
            }
            
            
            if self.arrayOfOffers.count == 0{
                self.currentStatus = .nothingFound
            }else{
                self.currentStatus = .results(self.arrayOfOffers)
            }
            completion()

        })
        
        return _refHandle
    }
    
    // we use this in .myBids table we get this form Users/$userId/Bid/$BidId
    func getMyBidsArray(path: String, completion: @escaping ()-> Void) -> FIRDatabaseHandle{
        
        let rootReference = FIRDatabase.database().reference()
        let reference = rootReference.child(path)
        currentStatus = .loading
        let _refHandle = reference.observe(.value, with:{ snapshot in
            //make sure that when we start the computation we have nothing in the array of offers
            self.arrayOfOffers = [Offer]()
            guard let value = snapshot.value as? [String: Any] else{
                self.currentStatus = .nothingFound
                completion()
                return
            }
            
            sleep(UInt32(1))
            for bidId in value.keys{
                
                //the node is a dictionary of the bidId key and contains the keys "offer" and is active.
                
                if let node = value[bidId] as? [String: Any], let offerDictionary = node["offer"] as? [String:String], let offer = Offer(offerDictionary) {
                    
                    offer.bidId = bidId
                    offer.latitude = self.appUser.latitude
                    offer.longitude = self.appUser.longitude
                    self.arrayOfOffers.append(offer)
                
                }
            }
            
            
            if self.arrayOfOffers.count == 0{
                self.currentStatus = .nothingFound
            }else{
                self.currentStatus = .results(self.arrayOfOffers)
            }
            completion()
            
        })
        
        return _refHandle
    }
    
    func getTransposeAcceptedOffer(path: String, completion: @escaping () -> Void){
        
        let rootReference = FIRDatabase.database().reference()
        let reference = rootReference.child(path)
        reference.observeSingleEvent(of: .value, with:{ snapshot in
            //make sure that when we start the computation we have nothing in the array of offers
            guard let value = snapshot.value as? [String: Any] else{
                return
            }
            
            for offerId in value.keys{
                
                if let offerDictionary = value[offerId] as? [String: String], let offer = Offer(offerDictionary) {
                    
                    let latitude = Double(offerDictionary[Constants.offerBidLocation.latitude]!)
                    let longitude = Double(offerDictionary[Constants.offerBidLocation.longitude]!)
                    offer.latitude = latitude
                    offer.longitude = longitude
                    self.transposeOffer = offer
                    
                    completion()
                    //we only run this code once 
                    return
                }
            }
            
        })
    }

}
