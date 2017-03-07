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
import OneSignal

class AcceptOfferViewController: UIViewController {

    var offer: Offer? // the offer should be no nil
    var storageReference: FIRStorageReference!
    let appUser = AppUser.sharedInstance
    let rootReference = FIRDatabase.database().reference()
    //var authorOfTheBid: String?
    var bidId: String?
    let tabBarId = "tabBar"
    let counterOfferBidId = "counterOffer"
    let annotation = MKPointAnnotation()
    var currentStatus: status = .acceptOffer
    
    enum status {
        case acceptOffer
        case offerAcceptedConfirmation
        case counterOfferConfirmation
    }
    
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
    
    
    
    
    
    @IBAction func acceptOffer(_ sender: Any) {
        
        switch currentStatus{
        case .acceptOffer:
            print("d")//acceptOfferAndWriteToFirebase()
        case .offerAcceptedConfirmation:
            print("confirmation")
        case .counterOfferConfirmation:
            print("conterofferConfirmation")
        }
        
        //sendNotificationOfAcceptence()
        performSegue(withIdentifier: tabBarId , sender: nil)

    }
  
    @IBAction func counteroffer(_ sender: Any) {
        
        performSegue(withIdentifier: counterOfferBidId, sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MKmapViewDelegate
        mapView.delegate = self
        configureStorage()
        setAlltheLabels()
    }
  
   

    func acceptOfferAndWriteToFirebase(){
        //we use this function to write the transposeOfferToFirebase 
        //since we are working with the transpose we mean "sell changed to buy", and to the info of the buyer instead of info of the seller
        var transposeOfferDictionary : [String:String] = [:]
        transposeOfferDictionary[Constants.offer.buyCurrencyCode] = offer?.sellCurrencyCode
        transposeOfferDictionary[Constants.offer.buyQuantity] = offer?.sellQuantity
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let now = Date()
        transposeOfferDictionary[Constants.offer.dateCreated] = dateFormatter.string(from: now)
        transposeOfferDictionary[Constants.offer.firebaseId] = appUser.firebaseId
        transposeOfferDictionary[Constants.offer.imageUrl] = appUser.imageUrl
        transposeOfferDictionary[Constants.offer.isActive] = "true"
        transposeOfferDictionary[Constants.offer.name] = appUser.name
        OneSignal.idsAvailable({ (_ oneSignalId, _ pushToken) in
            guard let oneSignalId = oneSignalId else{
                //TODO show an error
                return
            }
            transposeOfferDictionary[Constants.offer.oneSignalId] = oneSignalId
        })
        
        transposeOfferDictionary[Constants.offer.rateCurrencyRatio] = offer?.rateCurrencyRatio
        transposeOfferDictionary[Constants.offer.sellCurrencyCode] = offer?.buyCurrencyCode
        transposeOfferDictionary[Constants.offer.sellQuantity] = offer?.buyQuantity
        transposeOfferDictionary[Constants.offer.timeStamp] = "\(now.timeIntervalSince1970)"
        transposeOfferDictionary[Constants.offer.userRate] = offer?.userRate
        transposeOfferDictionary[Constants.offer.yahooCurrencyRatio] = offer?.yahooCurrencyRatio
        transposeOfferDictionary[Constants.offer.yahooRate] = offer?.yahooRate
        
        //write it to accept it offer
        var pathForTransposeOfAcceptedOffer = "/transposeOfacceptedOffer/\(offer!.firebaseId)/\(offer!.bidId!)"
        let acceptedfferAutoId = rootReference.child(pathForTransposeOfAcceptedOffer).childByAutoId().key
        pathForTransposeOfAcceptedOffer = pathForTransposeOfAcceptedOffer + "/\(acceptedfferAutoId)"
        let pathToOffersIAccepted = "/Users/\(appUser.firebaseId)/offersIAccepted/\(offer!.firebaseId)/\(offer!.bidId!)/\(acceptedfferAutoId)"
        rootReference.updateChildValues([pathForTransposeOfAcceptedOffer: transposeOfferDictionary, pathToOffersIAccepted: transposeOfferDictionary])
    }
    
    func configureStorage() {
        //configure storage using your firebase storage
        storageReference = FIRStorage.storage().reference()
    }
    
    func sendNotificationOfAcceptence(){
        // Create a reference to the file to download when the notification is recived
        let imageReference = FIRStorage.storage().reference().child("ProfilePictures/D3YbHsorypR9EbMBJxBogtqpRfy1.jpg")
        var urlString: String? = nil
        imageReference.downloadURL{ aUrl, error in
            
            if let error = error {
                // Handle any errors
                print("there was an error \(error)")
            } else {
                urlString = "\(aUrl!)"
                
                //we always need to include a message in English
                var contentsDictionary = ["en": "Go to My bids inside MonEx to take action, if you take no action the request will be dismissed automatically after 5 min"]
                let spanishMessage = "Dentro de MonEx seleciona Mis subastas y elige una opcion, si no eliges ninguna opcion la propuesta sera rechazada automaticamente despues de 5 min"
                let portugueseMessage = "Dentro na MonEx seleçione Mias Subastas y ecolia uma opçao, si voce nao elige niguma opçao a propuesta sera descartada automaticamente a pos 5 min"
                contentsDictionary["es"] = spanishMessage
                contentsDictionary["pt"] = portugueseMessage
                
                var headingsDictionary = ["en": "\(self.appUser.name) is interested in your offer"]
                let spanishTitle = "\(self.appUser.name) esta interesado en su oferta"
                let portugueseTitle = "\(self.appUser.name) esta interessado em sua oferta"
                headingsDictionary["es"] = spanishTitle
                headingsDictionary["pt"] = portugueseTitle
                
                var subTitileDictionary = ["en": "Continue with the transaction on MonEx"]
                let spansihSubTitle = "Continue con la transaccion dentro de MonEx"
                let portugueseSubTitle = "Continue com a transação no MonEx"
                subTitileDictionary["es"] = spansihSubTitle
                subTitileDictionary["pt"] = portugueseSubTitle
                
                //we use one signal to push the notification
                OneSignal.postNotification(["contents": contentsDictionary, "headings":headingsDictionary,"subtitle":subTitileDictionary,"include_player_ids": ["\(self.offer!.oneSignalId)"], "content_available": true, "mutable_content": true, "data":["imageUrl": urlString, "name": "\(self.appUser.name)", "distance": self.distanceLabel.text, "bidId": self.offer?.bidId!],"ios_category": "acceptOffer"], onSuccess: { (dic) in
                    print("THERE WAS NO ERROR")
                }, onFailure: { (Error) in
                    print("THERE WAS AN EROOR \(Error!)")
                })
            }
        }

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
            offerViewController.offer = offer 
            offerViewController.isCounterOffer = true
            offerViewController.distanceFromOffer = distanceLabel.text
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


