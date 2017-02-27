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
    var currentStatus: status = .notsearchedYet
    
    enum status{
        case notsearchedYet
        case loading
        case nothingFound
        case results([Offer])
    }

    
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
                
                //the node is a dictionary of the bid and contains the keys lasOfferInBid, latitude, longitude, userFirebaseId the latter is the id for the author of the bid.
                
                if let node = value[bidId] as? [String: Any], let authorOfTheBid = node[Constants.offerBidLocation.userFirebaseId] as? String, let oneSignalId = node[Constants.offerBidLocation.authorOneSignalId] as? String, let dictionary = node[Constants.offerBidLocation.lastOfferInBid] as? [String: String], let offer = Offer(dictionary) {
                    
                    offer.authorOfTheBid = authorOfTheBid
                    offer.oneSignalId = oneSignalId
                    offer.bidId = bidId
                    
                    if let latitude = node[Constants.offerBidLocation.latitude] as? Double, let longitude = node[Constants.offerBidLocation.longitude] as? Double {
                        offer.latitude = latitude
                        offer.longitude = longitude
                    }
                    
                    //if the offer is done by my I would not display it
                    if authorOfTheBid != self.appUser.firebaseId {
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
                
                //the node is a dictionary of the bid and contains the keys lasOfferInBid, latitude, longitude, userFirebaseId the latter is the id for the author of the bid.
                
                if let node = value[bidId] as? [String: Any], let offerDictionary = node["offer"] as? [String:String], let offer = Offer(offerDictionary) {
                    
                    offer.bidId = bidId
                    offer.authorOfTheBid = self.appUser.firebaseId
                    
                    if let latitude = node[Constants.offerBidLocation.latitude] as? Double, let longitude = node[Constants.offerBidLocation.longitude] as? Double {
                        offer.latitude = latitude
                        offer.longitude = longitude
                    }
                    
                    //if the offer is done by my I would not display it
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

    
}
