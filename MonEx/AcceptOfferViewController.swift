//
//  AcceptOfferViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/6/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import FirebaseStorageUI
import MapKit
import Firebase


class AcceptOfferViewController: UIViewController {

    var offer: Offer? // the offer should be no nil
    var storageReference: FIRStorageReference!
    let appUser = AppUser.sharedInstance
    //var authorOfTheBid: String?
    var bidId: String?
    let tabBarId = "tabBar"
    let counterOfferBidId = "counterOffer"
    let annotation = MKPointAnnotation()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var profileView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var sellQuantityTextLabel: UILabel!
    @IBOutlet weak var sellCurrencyLabel: UILabel!
    @IBOutlet weak var buyQuantityTextLabel: UILabel!
    @IBOutlet weak var buyCurrencyLabel: UILabel!
    @IBOutlet weak var sellLabel: UILabel!
    @IBOutlet weak var buyLabel: UILabel!
    @IBOutlet weak var offerAcceptanceDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MKmapViewDelegate
        mapView.delegate = self
        configureStorage()
        setAlltheLabels()
    }
    
    
    @IBAction func acceptOffer(_ sender: Any) {
        performSegue(withIdentifier: tabBarId , sender: nil)
    }
  
    @IBAction func counteroffer(_ sender: Any) {
        performSegue(withIdentifier: counterOfferBidId, sender: nil)
    }
    
    func configureStorage() {
        //configure storage using your firebase storage
        storageReference = FIRStorage.storage().reference()
    }
    
    
   
    //we have to waith for the appUser.getLocation to be successfull
    func appUserCompletion(success:Bool){
        if success{
            let sellerLocation = CLLocation(latitude: offer!.latitude! , longitude: offer!.longitude!)
            let distance = sellerLocation.distance(from: appUser.location!)
            let distanceFormatter = MKDistanceFormatter()
            distanceLabel.text = distanceFormatter.string(fromDistance: distance)
            zoomIn()
            dropApin()
        }
    }
    
    func zoomIn() {
        let deltaLatitude = abs(offer!.latitude! - appUser.latitude!) + 0.5*abs(offer!.latitude! - appUser.latitude!)
        let deltaLongitude = abs(offer!.longitude! - appUser.longitude!) + 0.3*abs(offer!.longitude! - appUser.longitude!)
        let span = MKCoordinateSpanMake(deltaLatitude, deltaLongitude)
        let centerLatitude = (offer!.latitude! + appUser.latitude!)/2
        let centerLongitude = (offer!.longitude! + appUser.longitude!)/2
        let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
       
    }

    func dropApin(){
        let coordinate = CLLocationCoordinate2D(latitude: offer!.latitude!, longitude: offer!.longitude!)
        annotation.coordinate = coordinate
        //we check if there is an annotation, if there is none we drop a pin, if there is one we update it
        //We need to because the userlocation counts as an annotation
        if mapView.annotations.count <= 1{
            mapView.addAnnotation(annotation)
        }else{
            annotation.coordinate = coordinate
        }
    }
    
    func setAlltheLabels(){
        nameLabel.text = offer!.name
        profileView.loadImage(url: offer!.imageUrl, storageReference: storageReference, saveContext: nil, imageId: appUser.imageId)
        appUser.completion = appUserCompletion
        appUser.getLocation(viewController: self, highAccuracy: true)
        sellQuantityTextLabel.text = offer!.sellQuantity
        buyQuantityTextLabel.text = offer!.buyQuantity
        sellCurrencyLabel.text = offer!.sellCurrencyCode
        buyCurrencyLabel.text = offer!.buyCurrencyCode
        sellLabel.text = NSLocalizedString("SELL:", comment: "SELL: AcceptOfferViewController")
        buyLabel.text = NSLocalizedString("BUY:", comment: "SELL: AcceptOfferViewController")
        
        offerAcceptanceDescription.text = NSLocalizedString(String(format:"I accept the offer to exchange %@ %@ at a rate of %@ , for a total amount of %@ %@", buyQuantityTextLabel.text!,buyCurrencyLabel.text!, offer!.rateCurrencyRatio, sellQuantityTextLabel.text!, sellCurrencyLabel.text!), comment: "I want to exchange %@cuantitySellTextField %@SellCurrencyLabel at a rate of %@rateTextField %@CurrencyRatioLabel, for a total amount of %@quantityBuyTextField %@buyCurrencyLabel: OfferViewController")

    }
    
    func formatterByCode(_ currencyCode: String)-> NumberFormatter{
        let formatter = NumberFormatter()
        //formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency
        //formatter.currencySymbol = ""
        formatter.currencyCode = currencyCode
        
        return formatter
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        if segue.identifier == tabBarId{
            let tabBarController = segue.destination as? UITabBarController
            let messagesViewController = tabBarController?.viewControllers?.last as? MessagesViewController
            let mapViewController = tabBarController?.viewControllers?.first as?
                MapViewController
            mapViewController?.offer = offer
            messagesViewController?.offer = offer
        }
        
        if segue.identifier == counterOfferBidId{
            let offerViewController = segue.destination as! OfferViewController
            
            offerViewController.user = FIRAuth.auth()?.currentUser
            offerViewController.formatterSell = formatterByCode((offer?.sellCurrencyCode)!)
            offerViewController.formatterBuy = formatterByCode((offer?.buyCurrencyCode)!)
            offerViewController.quantitySell = offer?.sellQuantity
            offerViewController.quantityBuy = offer?.buyQuantity
            offerViewController.yahooRate = Float((offer?.yahooRate)!)
            offerViewController.yahooCurrencyRatio = offer?.yahooCurrencyRatio
            offerViewController.userRate = Float((offer?.userRate)!)
            offerViewController.currencyRatio = offer?.rateCurrencyRatio
            
        }
    }
    

}

extension AcceptOfferViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = Constants.color.greenLogoColor
        pinView?.canShowCallout = true
        pinView?.animatesDrop = true
        //let smallSquare = CGSize(width: 30, height: 30)
       // let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        // button.setBackgroundImage(UIImage(named: "car"), forState: .Normal)
        //button.addTarget(self, action: #selector(ViewController.getDirections), for: .touchUpInside)
        //pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    
}


