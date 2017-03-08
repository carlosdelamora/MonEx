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
    let latitude = "latitude"
    let longitude = "longitude"
    let latitudeDelta = "latitudeDelta"
    let longitueDelta = "longitudeDelta"
    let annotation = MKPointAnnotation()
    var firstZoom = true
    fileprivate var _refHandle: FIRDatabaseHandle!
    
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        appUser.completion = appUserCompletion
        //we write to firebase even before getting the most current location, bacause this may take a while for bad reception 
        appUserCompletion(success: true)
        //set the delegate
        mapView.delegate = self
        getPeerLocation()
        //remove map anotations
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //we get new latitude and longitude with this function once we have it we write it to Firebase by using appUserCompletion
        appUser.isActive = true 
        appUser.getLocation(viewController: self, highAccuracy: true)
        //appUser.completion = appUserCompletion
        
        //if the region has been set before we want persistance
        if let regionDictionary = UserDefaults.standard.value(forKey: "mapRegion") as? [String: Double]{
            
            guard let latitudeDelta = regionDictionary[latitudeDelta], let longitudeDelta = regionDictionary[longitueDelta] , let latitude = regionDictionary[latitude], let longitude = regionDictionary[longitude] else{
                return
            }

            
            var span = MKCoordinateSpan()
            span.latitudeDelta = latitudeDelta
            span.longitudeDelta = longitudeDelta
            DispatchQueue.main.async {
                self.mapView.region.center.latitude = latitude
                self.mapView.region.center.longitude = longitude
                self.mapView.region.span = span
            }
            
            print("the view will appear the latutude delta is \(regionDictionary["latitudeDelta"]!)")
            print(mapView.region.span.latitudeDelta)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        referenceToLocations.removeObserver(withHandle: _refHandle)
    }
    
    // we use this function to write to write the location to Firebase
    //we use this function to write to location gets called every second or so
    func appUserCompletion(success: Bool){
        let pathOfferBidUserId = "\((offer?.bidId)!)/\(appUser.firebaseId)"
        appUser.writeToFirebase(withPath: pathOfferBidUserId)
    }
    
    
    func getPeerLocation(){
        let pathToPersonLocation = "\((offer?.bidId)!)"//\((offer?.authorOfTheBid)!)"
        referenceToLocations = FIRDatabase.database().reference().child(pathToPersonLocation)
        _refHandle = referenceToLocations.observe(.value, with: { (snapshot) in
            
            guard let dictionaryOfuserIdLocation = snapshot.value as? [String: Any] else{
                return
            }

            //we get the keys of the dictionaryOfUserIdLocation, which should be user ids, we search for the user id that is not ours. 
            for key in dictionaryOfuserIdLocation.keys{
                if key != self.appUser.firebaseId{
                    guard let latLongDictionary = dictionaryOfuserIdLocation[key] as? [String: Any] else{
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
                }
            }
            
            
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
        if firstZoom{
            firstZoom = false
            DispatchQueue.main.async {
                self.mapView.setRegion(region, animated: true)
            }
        }
        
        
    }
    
    func  placeImageView(){
        let centerCoordinates = CLLocationCoordinate2D(latitude: peerLatitude!, longitude: peerLongitude!)
        
        if mapView.annotations.count <= 1{
            
            annotation.coordinate = centerCoordinates
            mapView.addAnnotation(annotation)
            
        }else{
           annotation.coordinate = centerCoordinates
        }
    }
    
    //get persistent data for the region
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionDictionary[latitude] = mapView.region.center.latitude
        regionDictionary[longitude] = mapView.region.center.longitude
        regionDictionary[latitudeDelta] = mapView.region.span.latitudeDelta
        regionDictionary[longitueDelta] = mapView.region.span.longitudeDelta
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
