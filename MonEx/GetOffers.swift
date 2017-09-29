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
            //print("\(arrayOfOffers.count)")
        }
    }
    let appUser = AppUser.sharedInstance
    var transposeOffer : Offer?
    var currentStatus: status = .notsearchedYet
    var counteroffer: Offer?
    
    enum status{
        case notsearchedYet
        case loading
        case nothingFound
        case results([Offer])
    }

    //we use this in the .browseOffers table, we get this from the path offerBidsLocation/$bidId/lastOfferInBid
    func getArraysOfOffers(path: String, lookingToBuy:String?, lookingToSell:String?, completion: @escaping ()-> Void) -> FIRDatabaseHandle{
        var lookingToBuyCode: String
        lookingToBuyCode = lookingToBuy ?? ""
        //make sure that when we start the computation we have nothing in the array of offers
        let rootReference = FIRDatabase.database().reference()
        let reference = rootReference.child(path)
        currentStatus = .loading
        let _refHandle = reference.queryOrdered(byChild: "lastOfferInBid/sellCurrencyCode").queryEqual(toValue: lookingToBuyCode).observe(.value, with:{ snapshot in
            
             //make sure that when we start the computation we have nothing in the array of offers
            self.arrayOfOffers = [Offer]()
            guard let value = snapshot.value as? [String: Any] else{
                self.currentStatus = .nothingFound
                completion()
                return
            }
            
            sleep(UInt32(1))
            value.keys.forEach{ bidId in
                
                //the node is a dictionary of the bidId key and contains the keys lasOfferInBid, latitude, longitude, userFirebaseId the latter is the id for the author of the bid.
                if let node = value[bidId] as? [String: Any], let dictionary = node[Constants.offerBidLocation.lastOfferInBid] as? [String: String], let offer = Offer(dictionary), let lookingToSell = lookingToSell {
                    
                    
                    offer.bidId = bidId
                    
                    //we get the location of the offers from the offerBidLocation which is the most accurate
                    guard let latitude = node[Constants.offerBidLocation.latitude] as? Double, let longitude = node[Constants.offerBidLocation.longitude] as? Double else{
                        return
                    }
                    
                    offer.latitude = latitude
                    offer.longitude = longitude
                    //in order to display the offer, has to be done by somone else and not be active.
                    //also what the user is trying to sell should be equal to what the other user is trying to buy
                    if offer.firebaseId != self.appUser.firebaseId && offer.offerStatus.rawValue == Constants.offerStatus.nonActive, lookingToSell == offer.buyCurrencyCode{
                            
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
                    //we give the offer latitud and longitud of the user here but we may be choosing an accepted offer that has different locations. 
                    //we should check if the user is the one who created the offer 
                    if offer.firebaseId == self.appUser.firebaseId{
                        offer.latitude = self.appUser.latitude
                        offer.longitude = self.appUser.longitude
                    }
                    if offer.offerStatus.rawValue != Constants.offerStatus.complete{
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
    
    
    
    func getCounterOffer(path: String, completion: @escaping () -> Void){
        
        let rootReference = FIRDatabase.database().reference()
        let reference = rootReference.child(path)
        reference.observeSingleEvent(of: .value, with:{ snapshot in
            //make sure that when we start the computation we have nothing in the array of offers
            guard let value = snapshot.value as? [String: Any] else{
                completion()
                return
            }
            
            var keys = [String]()
            for key in value.keys{
                keys.append(key)
            }
            
            keys.sort()
            
            if let offerId = keys.last{
                
                if let offerDictionary = value[offerId] as? [String: String], let offer = Offer(offerDictionary) {
                    
                    let latitude = Double(offerDictionary[Constants.offerBidLocation.latitude]!)
                    let longitude = Double(offerDictionary[Constants.offerBidLocation.longitude]!)
                    offer.latitude = latitude
                    offer.longitude = longitude
                    self.counteroffer = offer
                    
                    completion()

                }
            }
            
        })

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
