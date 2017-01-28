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


class AppUser:NSObject {
    
    //properties regarding location
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError : Error?
    var timer: Timer?
    var latitude: Double?
    var longitude: Double?

    
    
    static let sharedInstance = AppUser()
    
    var name: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var FirebaseId: String = ""
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
        self.FirebaseId = ""
        self.imageUrl = ""
        self.imageId = ""
        
    }
    
    func getLocation(viewController:UIViewController){
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined{
            locationManager.requestWhenInUseAuthorization()
        }
        
        if authStatus == .restricted || authStatus == .denied{
            showLocationServicesDeniedAlert(viewController: viewController)
            return
        }
        startLocationManager()
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
        print("did update location \(newLocation)")
        location = newLocation
        lastLocationError = nil
        self.latitude = newLocation.coordinate.latitude
        self.longitude = newLocation.coordinate.longitude
    }
    
    func showLocationServicesDeniedAlert(viewController: UIViewController){
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func stopLocationManager(){
        if updatingLocation{
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    func startLocationManager(){
        //locationServicesEnable = true to get more accurate we try to avoid this to save battery. Use it one a transaction started
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
}

