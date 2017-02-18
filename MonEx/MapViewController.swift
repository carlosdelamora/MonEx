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
    
    var regionDictionary = [String: Double]()
    var referenceToLocations : FIRDatabaseReference!
    var offer: Offer?
    let appUser = AppUser.sharedInstance
    var peerLatitude: Double?
    var peerLongitude: Double?
    /*var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
        imageView.image = UIImage(named: "USD")
        return imageView
    }()*/
    
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        appUser.completion = appUserCompletion
        //set the delegate
        mapView.delegate = self
        getPeerLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //we get new latitude and longitude with this function once we have it we write it to Firebase by using appUserCompletion
        appUser.getConcurrentLocation(viewController: self)
        appUser.completion = appUserCompletion
        
        //if the region has been set before we want persistance
        if let regionDictionary = UserDefaults.standard.value(forKey: "mapRegion") as? [String: Double]{
            
            
            var span = MKCoordinateSpan()
            span.latitudeDelta = regionDictionary["latitudeDelta"]!
            span.longitudeDelta = regionDictionary["longitudeDelta"]!
            DispatchQueue.main.async {
                self.mapView.region.center.latitude = self.regionDictionary["latitude"]!
                self.mapView.region.center.longitude = self.regionDictionary["longitude"]!
                self.mapView.region.span = span
            }
            
            print("the view will appear the latutude delta is \(regionDictionary["latitudeDelta"]!)")
            print(mapView.region.span.latitudeDelta)
        }
        
    }
    
    // we use this function to write to write the location to Firebase
    //we use this function to write to location gets called every 30 seconds or so 
    func appUserCompletion(success: Bool){
        let pathOfferBidUserId = "\((offer?.bidId)!)/\(appUser.firebaseId)"
        referenceToLocations = FIRDatabase.database().reference().child(pathOfferBidUserId)
        let values = [Constants.offerBidLocation.latitude: appUser.latitude, Constants.offerBidLocation.longitude: appUser.longitude]
        referenceToLocations.setValue(values)
    }
    
    func getPeerLocation(){
        let pathToPersonLocation = "\((offer?.bidId)!)"//\((offer?.authorOfTheBid)!)"
        referenceToLocations = FIRDatabase.database().reference().child(pathToPersonLocation)
        referenceToLocations.observe(.childChanged, with: { (snapshot) in
            
            //if the sanpshot key is yours that meens is your location the one that was updated and you already have this info.
            guard snapshot.key != self.appUser.firebaseId else{
                return
            }
            
            guard let latLongDictionary = snapshot.value as? [String: Any] else{
                return 
            }
            
            guard let latitude = latLongDictionary["latitude"] as? Double else{
                return
            }
            self.peerLatitude = latitude
            
            guard let longitude = latLongDictionary["longitude"] as? Double else{
                return
            }
            self.peerLongitude = longitude
            
            self.zoomIn()
            self.placeImageView()
        })
    }
    
    func zoomIn() {
        let deltaLatitude = abs(peerLatitude! - appUser.latitude!) + 0.5*abs(peerLatitude! - appUser.latitude!)
        let deltaLongitude = abs(peerLongitude! - appUser.longitude!) + 0.3*abs(peerLongitude! - appUser.longitude!)
        let span = MKCoordinateSpanMake(deltaLatitude, deltaLongitude)
        let centerLatitude = (peerLatitude! + appUser.latitude!)/2
        let centerLongitude = (peerLongitude! + appUser.longitude!)/2
        let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        let region = MKCoordinateRegion(center: center, span: span)
        DispatchQueue.main.async {
            self.mapView.setRegion(region, animated: true)
        }
        
        
    }
    
    func  placeImageView(){
        let centerCoordinates = CLLocationCoordinate2D(latitude: peerLatitude!, longitude: peerLongitude!)
        let annotation = MKPointAnnotation()
        annotation.coordinate = centerCoordinates
        mapView.addAnnotation(annotation)
        
    }
    
    //get persistent data for the region
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionDictionary["latitude"] = mapView.region.center.latitude
        regionDictionary["longitude"] = mapView.region.center.longitude
        regionDictionary["latitudeDelta"] = mapView.region.span.latitudeDelta
        regionDictionary["longitudeDelta"] = mapView.region.span.longitudeDelta
        UserDefaults.standard.set(regionDictionary, forKey: "mapRegion")
    }
    
   
}

extension MapViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        // Better to make this class property
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "USDsmall")
        }
        
        return annotationView
    }
    
}
