//
//  MapViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/16/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class MapViewController: UIViewController {

   var referenceToLocations : FIRDatabaseReference!
   var offer: Offer?
   let appUser = AppUser.sharedInstance
   
    
    
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        appUser.completion = appUserCompletion
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { (timer) in
            self.appUser.getLocation(viewController: self, highAccuracy: true)
        }
        
    }
    
    
    //we use this function to write to location gets called every 30 seconds or so 
    func appUserCompletion(success:Bool){
        let pathToOfferBid = "\((offer?.bidId)!)/\(appUser.firebaseId)"
        referenceToLocations = FIRDatabase.database().reference().child(pathToOfferBid)
        let values = [Constants.offerBidLocation.latitude: appUser.latitude, Constants.offerBidLocation.longitude: appUser.latitude]
        referenceToLocations.setValue(values)
    }
    
   
}
