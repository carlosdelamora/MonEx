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
class AppUser:NSObject {
    
    //firebase properties
    var rootReference: FIRDatabaseReference!
    var user: FIRUser?
    typealias gotLocation = (Bool) -> Void
    var referenceToLocations : FIRDatabaseReference!
    
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
    
    
    static let sharedInstance = AppUser()
    
    var name: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var firebaseId: String = ""
    var imageUrl: String = ""
    var imageId: String = ""
    
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
    
    func getProfile(){
        user = FIRAuth.auth()?.currentUser!
        rootReference = FIRDatabase.database().reference()
        rootReference.child("Users/\((user?.uid)!)/Profile").observeSingleEvent(of: .value, with:{ snapshot in
            
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
            print(error.localizedDescription)
        }
    }
}

extension AppUser: CLLocationManagerDelegate{
    
    //MARK:location manager delegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("did fail with error \(error)")
        if (error as NSError).code == CLError.locationUnknown.rawValue{
            return
        }
        
        lastLocationError = error
        stopLocationManager()
    }
    
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
                        //we stop the location services but still want to record significant changes
                        startLocationManager(highAccuracy: highAccuracy)
                    }
                    guard let completion = completion else{
                        return
                    }
                    
                    completion(success)
                }
                
            }
        }else{
            location = newLocation
            self.latitude = newLocation.coordinate.latitude
            self.longitude = newLocation.coordinate.longitude
            
            //print("did update location \(newLocation) for significant changes")
            //print(" the horizontal accuracy is \(newLocation.horizontalAccuracy)")
            
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
            referenceToLocations = FIRDatabase.database().reference().child(path)
            let values = [Constants.offerBidLocation.latitude: latitude, Constants.offerBidLocation.longitude: longitude]
            referenceToLocations.setValue(values)
    }
}

