//
//  AppUser.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/18/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import FirebaseAuth
import Firebase
import CoreData

class AppUser:NSObject {
    
    //firebase properties
    var rootReference: FIRDatabaseReference!
    var user: FIRUser?
    typealias gotLocation = (Bool) -> Void
    var referenceToPath : FIRDatabaseReference!
    var context : NSManagedObjectContext? = nil
    
    
    //properties regarding location
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError : Error?
    var timer: Timer?
    var latitude: Double?
    var longitude: Double?
    var completion: gotLocation? = nil
    var highAccuracy: Bool = false
    var counter: Int = 0
    var isActive: Bool = false
    var bidIds = [String]()
    
    static let sharedInstance = AppUser()
    
    var name: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var firebaseId: String = ""
    var imageUrl: String = ""
    var imageId: String = ""
    
    
    enum bidStatus: String{
        case moreThanFiveUserLastToWrite = "moreThanFiveUserLastToWrite"
        case moreThanFiveOtherLastToWrite = "moreThanFiveOtherLastToWrite"
        case lessThanFive = "lessThanFive"
        case noBid = "noBid"
        case nonActive = "nonActive"
        case active = "active"
        case counterOffer = "counterOffer"
        case counterOfferApproved = "counterOfferApproved"
        case approved = "approved"
        case complete = "complete"
    }
    
    
    private override init(){
    }
    
    deinit{
        print("we deinitialize app user \(self)")
    }
    
    func clear(){
        
        self.location = nil
        self.updatingLocation = false
        self.lastLocationError = nil
        self.timer = nil
        self.latitude = nil
        self.longitude = nil
        self.name = ""
        self.lastName = ""
        self.email = ""
        self.phoneNumber = ""
        self.firebaseId = ""
        self.imageUrl = ""
        self.imageId = ""
        self.completion = nil
        self.bidIds = [String]()
    }
    
    func getLocation(viewController: UIViewController, highAccuracy:Bool){
        //set the bool for highAccuracy 
        self.highAccuracy = highAccuracy
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined{
            locationManager.requestAlwaysAuthorization()
        }
        
        if authStatus == .restricted || authStatus == .denied{
            showLocationServicesDeniedAlert(viewController: viewController)
            return
        }
        startLocationManager(highAccuracy: highAccuracy)
        
    }
    
    func getRating(firebaseId:String, completion: @escaping (_ rating:Double)->Void ){
        rootReference = FIRDatabase.database().reference()
        var rating: Double?
        rootReference.child("\(firebaseId)/rating").observeSingleEvent(of: .value, with:{
            snapshot in
            
            guard let ratingSnap = snapshot.value as? Double else{
                return
            }
            rating = round(ratingSnap*10)/10
            
            
            completion(rating!)
        })
    }
    
    
    func getProfile(){
        user = FIRAuth.auth()?.currentUser!
        rootReference = FIRDatabase.database().reference()
        rootReference.child("Users/\((user?.uid)!)/Profile").observeSingleEvent(of: .value, with:{ snapshot in
            
            
            print("the get profile closure gets called")
            guard let value = snapshot.value as? [String:String] else{
                return
            }
            if let name = value[Constants.profile.name], let lastName = value[Constants.profile.lastName], let email = value[Constants.profile.email], let phoneNumber = value[Constants.profile.phoneNumber], let imageId = value[Constants.profile.imageId], let imageUrl = value[Constants.profile.imageUrl], let firebaseId = value[Constants.profile.firebaseId]{
            
                self.name = name
                self.lastName = lastName
                self.email = email
                self.phoneNumber = phoneNumber
                self.imageId = imageId
                self.imageUrl = imageUrl
                self.firebaseId = firebaseId
            }
        }){ error in
            print("the get profile closure gets called with error")
            print(error.localizedDescription)
        }
    }
}

extension AppUser: CLLocationManagerDelegate{
    
    //MARK:location manager delegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        if (error as NSError).code == CLError.locationUnknown.rawValue{
            print("did fail with error \(error)")
            return
        }
        
        lastLocationError = error
        stopLocationManager()
    }
    
    // the locationManager does not do well on the IPad, takes to long to update and therefore never writes to firebase. 
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.last!
        
        if highAccuracy{
            // newLoction time created - currentTime < -5 is too old
            if newLocation.timestamp.timeIntervalSinceNow < -5{
                return
            }
            
            //if the horizontalAccurancy is less than zero, that means is usless and we ignore it
            if newLocation.horizontalAccuracy < 0 {
                return
            }
            //we set a counter and if after 10 tries it does not improve the acccuracy we still record the location
            counter += 1
            if counter > 10{
                location = newLocation
                self.latitude = newLocation.coordinate.latitude
                self.longitude = newLocation.coordinate.longitude
                if let completion = completion{
                     completion(true)
                }
            }
            
            if location == nil || newLocation.horizontalAccuracy <= location!.horizontalAccuracy {
                
                var success = false
                lastLocationError = nil
                location = newLocation
                counter = 0
                
                self.latitude = newLocation.coordinate.latitude
                self.longitude = newLocation.coordinate.longitude
                
                //print("did update location \(newLocation)")
                //print(" the horizontal accuracy is \(newLocation.horizontalAccuracy)")
                
                if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                    print("***we are done")
                    
                    success = true
                    //if the transaction is active we do not stop the location manager, and want to continue with high accuracy.
                    if !isActive{
                        stopLocationManager()
                        highAccuracy = false
                    }
                    
                    
                    guard let completion = completion else{
                        return
                    }
                    
                    completion(success)
                }
                
            }
        }else{
            //high accuracy is false
            location = newLocation
            self.latitude = newLocation.coordinate.latitude
            self.longitude = newLocation.coordinate.longitude
            self.updateAllBidLocationsInFirebase()
        }

    }
    
    func showLocationServicesDeniedAlert(viewController: UIViewController){
        //make the presentation be on the main thread 
        DispatchQueue.main.async {
            let alert = UIAlertController(title: NSLocalizedString("Location Services Disabled", comment: "Location Services Disabled: AppUser"), message: NSLocalizedString("Please enable location services for this app in settings -> Location Services look for the app MonEx and change status to while using", comment: "Please enable location services for this app in settings -> Location Services look for the app MonEx and change status to while using: AppUser"), preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func stopLocationManager(){
        if updatingLocation{
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            //locationManager.stopMonitoringSignificantLocationChanges()
        }
    }
    
    func startLocationManager(highAccuracy:Bool){
        //locationServicesEnable = true to get more accurate we try to avoid this to save battery. Use it one a transaction started
        
        if CLLocationManager.locationServicesEnabled() && highAccuracy{
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }else if CLLocationManager.significantLocationChangeMonitoringAvailable(){
            locationManager.delegate = self
            locationManager.startMonitoringSignificantLocationChanges()
            updatingLocation = true
        }
    }

    
    func writeToFirebase(withPath path: String){
            referenceToPath = FIRDatabase.database().reference().child(path)
        if let values = [Constants.offerBidLocation.latitude: latitude, Constants.offerBidLocation.longitude: longitude] as? [String : Double] {
                referenceToPath.updateChildValues(values)
        }
    }
    
    func activateAndDeActivateOffersInFirebase(values dictionary:[String: String]){
        referenceToPath = FIRDatabase.database().reference()
        referenceToPath.updateChildValues(dictionary)
    }
    
    func updateBidStatus(newInfo: PublicBidInfo, completion: @escaping (_ error:Error?, _ committed:Bool, _ snapshot:FIRDataSnapshot?) -> Void ){
        referenceToPath = FIRDatabase.database().reference().child("bidIdStatus/\(newInfo.bidId)")
        referenceToPath.runTransactionBlock({ (currentData) -> FIRTransactionResult in
            
            if var dictionary = currentData.value as? [String: Any]{
                
                //we do have some data 
                //we check if I have access to it
                if self.firebaseId != dictionary[Constants.publicBidInfo.authorOfTheBid] as! String && self.firebaseId != dictionary[Constants.publicBidInfo.otherUser] as! String{
                    let error: Error = "not able to read/write" as! Error
                    completion(error, false, nil)
                    return FIRTransactionResult.success(withValue: currentData)
                    
                }
                
                dictionary[Constants.publicBidInfo.status] = newInfo.status
                dictionary[Constants.publicBidInfo.lastOneToWrite] = newInfo.lastOneToWrite
                dictionary[Constants.publicBidInfo.timeStamp] = newInfo.timeStamp
                currentData.value = dictionary
                
                
                
                return FIRTransactionResult.success(withValue: currentData)
            }else{
                //there is no Public Info we should create one 
                var dictionary = [String: Any]()
                dictionary[Constants.publicBidInfo.authorOfTheBid] = newInfo.authorOfTheBid
                dictionary[Constants.publicBidInfo.bidId] = newInfo.bidId
                dictionary[Constants.publicBidInfo.lastOneToWrite] = self.firebaseId
                dictionary[Constants.publicBidInfo.otherUser] = newInfo.otherUser
                dictionary[Constants.publicBidInfo.status] = newInfo.status
                dictionary[Constants.publicBidInfo.timeStamp] = newInfo.timeStamp
                currentData.value = dictionary
                return FIRTransactionResult.success(withValue: currentData)
            }
        
        }, andCompletionBlock: completion)
        
    }
    
    func getTheBidsIds(){
        user = FIRAuth.auth()?.currentUser!
        rootReference = FIRDatabase.database().reference()
        rootReference.child("Users/\((user?.uid)!)/Bid").observeSingleEvent(of: .value, with: { (snapshot) in
            
            for item in snapshot.children {
                let snap = item as! FIRDataSnapshot
                self.bidIds.append(snap.key)
                print("bidIds \(self.bidIds)")
            }
        })

    }
    
    func updateAllBidLocationsInFirebase(){
        let values = [Constants.offerBidLocation.latitude: latitude, Constants.offerBidLocation.longitude: longitude]
        var pathArray = [String: Double]()
        //we construct a dictionary with keys all the paths of the bids
        for bidId in bidIds{
            let path = "/\(Constants.offerBidLocation.offerBidsLocation)/\(bidId)"
            let pathLatitude = path + "/\(Constants.offerBidLocation.latitude)"
            let pathLongitude = path + "/\(Constants.offerBidLocation.longitude)"
            pathArray[pathLatitude] = values[Constants.offerBidLocation.latitude]!
            pathArray[pathLongitude] = values[Constants.offerBidLocation.longitude]!
        }
        if pathArray.count > 0{
            rootReference = FIRDatabase.database().reference()
            rootReference.updateChildValues(pathArray) { (error, reference) in
                
                if error != nil{
                    print("we could not update locations because of the \(error)")
                }
            }
        }else{
            print("there are no bidId's")
        }
    }
    
    
    func getBidStatus(bidId: String, completion: @escaping (bidStatus) -> Void){
        
        var status = bidStatus(rawValue: Constants.appUserBidStatus.noBid)!
        
        rootReference.child("bidIdStatus/\(bidId)").observeSingleEvent(of: .value, with:{ (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else{
                completion(status)
                return
            }
            
            guard let timeStamp = dictionary[Constants.publicBidInfo.timeStamp] as? Double else{
                return
            }
            

            guard let lastOneToWrite = dictionary[Constants.publicBidInfo.lastOneToWrite] as? String else{
                return
            }
            
            
            
            guard let offerStatus = dictionary[Constants.publicBidInfo.status] as? String else{
                return
            }
            
            switch offerStatus{
            case Constants.offerStatus.nonActive, Constants.offerStatus.approved, Constants.offerStatus.counterOfferApproved, Constants.offerStatus.complete:
                status = bidStatus(rawValue: offerStatus)!
                completion(status)
                return
            case Constants.offerStatus.active, Constants.offerStatus.counterOffer:
                let date = Date(timeIntervalSince1970: timeStamp)
                //if the time is less than 5 minutes, we return this case.
                if date.timeIntervalSinceNow > -Constants.timeToRespond.timeToRespond{
                    status = bidStatus(rawValue: Constants.appUserBidStatus.lessThanFive)!
                    completion(status)
                    return
                }else{
                    //we only care about the time expired if is an active offer or a counterOffer otherwise we are not waiting for any specific action 
                    if lastOneToWrite == self.firebaseId{
                        status = bidStatus(rawValue: Constants.appUserBidStatus.moreThanFiveUserLastToWrite)!
                    }else{
                        status = bidStatus(rawValue: Constants.appUserBidStatus.moreThanFiveOtherLastToWrite)!
                    }
                }

            default:
                break
            }
            
            completion(status)
           
        })
        
        
    }
    
    
    //get other offer information
    func getOtherOffer(bidId: String, completion: @escaping (OtherOffer?) -> Void){
        
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
            completion(otherOffer)
        }
        
    }
    
    func deleteInfoTerminated(bidId: String){
        
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
            
            
            
            self.getOtherOffer(bidId: bidId){ otherOffer in
                
                guard let otherOffer = otherOffer else{
                    return
                }
                var pathForBidStatus = "/bidIdStatus/\(bidId)" // set to Null if status is completed otherwise add the path status and set to completed
                let pathForTranspose = "/transposeOfacceptedOffer/\(otherOffer.firebaseIdOther!)/\(bidId)"// set to Null if status is completed otherwise do nothing
                let pathForBidLocation = "/offerBidsLocation/\(bidId)/lastOfferInBid" // set to Null if status is completed otherwise do nothing
                let pathToMyBids = "/Users/\(self.firebaseId)/Bid/\(bidId)/offer/offerStatus" //update to completed
                //set to Null if status is completed otherwise do nothing we need to use the set function from firebase to aviod rejection atomic rejection by an empty offer or counteroffer
                let pathForCounterOffer = "/counterOffer/\(authorOfTheBid)/\(bidId)"//set to null
                //set to Null if status is completed otherwise do nothing we need to use the set function from firebase to aviod rejection atomic rejection by an empty offer or counteroffer
                let pathForCounterOfferOther = "/counterOffer/\(otherUser)/\(bidId)"
                
                
                if bidIdStatus == Constants.appUserBidStatus.halfComplete || bidIdStatus == Constants.appUserBidStatus.complete{
                    
                    self.rootReference.updateChildValues([pathForBidStatus: NSNull(), pathForBidLocation: NSNull(), pathForTranspose: NSNull(), pathToMyBids: Constants.offerStatus.complete])
                    self.rootReference.updateChildValues([pathForCounterOffer: NSNull()])
                    self.rootReference.updateChildValues([pathForCounterOfferOther: NSNull()])
                    
                }else{
                    pathForBidStatus = "/bidIdStatus/\(bidId)" + "/\(Constants.publicBidInfo.status)"
                    self.rootReference.updateChildValues([pathForBidStatus: Constants.appUserBidStatus.halfComplete, pathToMyBids: Constants.offerStatus.halfComplete])
                }
            }

        })
    }

    
    
}

