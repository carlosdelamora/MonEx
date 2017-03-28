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
import Cosmos
import CoreData

class AcceptOfferViewController: UIViewController {

    var offer: Offer? // the offer should be no nil
    var storageReference: FIRStorageReference!
    let appUser = AppUser.sharedInstance
    let rootReference = FIRDatabase.database().reference()
    //var authorOfTheBid: String?
    var bidId: String?
    let tabBarId = "tabBar"
    let counterOfferBidId = "counterOffer"
    let ratingId = "rating"
    let annotation = MKPointAnnotation()
    var currentStatus: status = .acceptOffer
    var offerNewStatusRawValue: String = Constants.offerStatus.nonActive
    var context: NSManagedObjectContext? = nil
    
    enum status {
        case acceptOffer
        case offerAcceptedNeedConfirmation
        case waitingForConfirmation
        case counterOfferConfirmation
        case offerConfirmed
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
    
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var counterOfferButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    @IBOutlet weak var cosmosView: CosmosView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //MKmapViewDelegate
        mapView.delegate = self
        // get core data context 
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        
        configureStorage()
        view.backgroundColor = Constants.color.greyLogoColor
        
        
        
        
        appUser.getRating(firebaseId: (offer?.firebaseId)!){ rating in
            
            if rating <= 0{
                DispatchQueue.main.async {
                    self.cosmosView.rating = 1
                    self.cosmosView.settings.totalStars = 1
                    self.cosmosView.settings.filledColor = .lightGray
                    self.cosmosView.settings.filledBorderWidth = 1
                    self.cosmosView.settings.filledBorderColor = Constants.color.greenLogoColor
                    self.cosmosView.text = NSLocalizedString("Not rated", comment: "Not rated")
                }
                
            }else{
                DispatchQueue.main.async {
                    self.cosmosView.rating = rating
                    self.cosmosView.settings.fillMode = .precise
                    self.cosmosView.settings.filledColor = .yellow
                    self.cosmosView.settings.emptyBorderColor = .yellow
                    self.cosmosView.settings.filledBorderColor = .yellow
                    self.cosmosView.tintColor = .blue
                    self.cosmosView.text = "\(rating)"
                }
            }
        }

    }
    
    override func viewWillAppear(_ animated:Bool){
        super.viewWillAppear(animated)
        setAlltheLabels()
        
    }
    
    
    
    @IBAction func acceptOffer(_ sender: Any) {
        
            self.appUser.getBidStatus(bidId: offer!.bidId!, completion: { status in
                switch status.rawValue{
                    
              //if the offer is completed go directly to raiting
                case Constants.appUserBidStatus.complete:
                    self.performSegue(withIdentifier: self.ratingId, sender: nil)
                case Constants.appUserBidStatus.moreThanFiveOtherLastToWrite,Constants.appUserBidStatus.moreThanFiveUserLastToWrite:
                    //in this case the we show the transaction has expired and update the bid to non active
                    DispatchQueue.main.async {
                        self.showExpiredAlert()
                    }
                    let pathToUpdate = "/Users/\(self.appUser.firebaseId)/Bid/\(self.offer!.bidId!)/offer/\(Constants.offer.offerStatus)"
                    let lastOfferInBidStatusPath = "offerBidsLocation/\(self.offer!.bidId!)/lastOfferInBid/\(Constants.offer.offerStatus)"
                    self.rootReference.updateChildValues( [pathToUpdate: Constants.offerStatus.nonActive])
                    self.rootReference.updateChildValues([lastOfferInBidStatusPath: Constants.offerStatus.nonActive])
                    self.deleteInfo(bidId: self.offer!.bidId!)
                    
                default:// Constants.appUserBidStatus.noBid, Constants.appUserBidStatus.lessThanFive, Constants.appUserBidStatus.approved, Constants.appUserBidStatus.nonActive:
                    //less than five minutes or if is active it should procceed to the next VC
                    switch self.currentStatus{
                    case .acceptOffer:
                        self.acceptOfferAndWriteToFirebase()
                        self.sendNotificationOfAcceptence()
                    case .waitingForConfirmation:
                        print("waiting for confirmation")
                    //sendNotificationOfAcceptence()
                    case .offerAcceptedNeedConfirmation:
                        self.acceptOfferAndWriteToFirebase()
                        self.sendNotificationOfAcceptence()
                        self.performSegue(withIdentifier: self.tabBarId , sender: nil)
                    case .counterOfferConfirmation:
                        //TODO: accept and write to firebase and send notification of acceptance
                        self.acceptOfferAndWriteToFirebase()
                        self.sendNotificationOfAcceptence()
                        print("conterofferConfirmation")
                        self.performSegue(withIdentifier: self.tabBarId , sender: nil)
                    case .offerConfirmed:
                        print("offer confirmed ")
                        self.performSegue(withIdentifier: self.tabBarId , sender: nil)
                    }
   
                    
                }
                
                
            })
       
        
    }
  
    @IBAction func counteroffer(_ sender: Any) {
        performSegue(withIdentifier: counterOfferBidId, sender: nil)
    }
    
    
    
    @IBAction func reject(_ sender: UIButton) {
        
        self.appUser.getBidStatus(bidId: offer!.bidId!, completion: { status in
            switch status.rawValue{
            case Constants.appUserBidStatus.lessThanFive, Constants.appUserBidStatus.approved:
                //less than five minutes or if is active it should procceed to the next VC
                self.rejectAndWriteToFirebase()
                self.sendNotificationOfRejection()
            default:
                //in this case the we show the transaction has expired and update the bid to non active
                DispatchQueue.main.async {
                    self.showExpiredAlert()
                }
                let pathToUpdate = "/Users/\(self.appUser.firebaseId)/Bid/\(self.offer!.bidId!)/offer/\(Constants.offer.offerStatus)"
                let lastOfferInBidStatusPath = "offerBidsLocation/\(self.offer!.bidId!)/lastOfferInBid/\(Constants.offer.offerStatus)"
                self.rootReference.updateChildValues( [pathToUpdate: Constants.offerStatus.nonActive])
                self.rootReference.updateChildValues([lastOfferInBidStatusPath: Constants.offerStatus.nonActive])
                self.deleteInfo(bidId: self.offer!.bidId!)
            }
            
        })

        
    }
    
    
    func goToRating(){
        performSegue(withIdentifier: ratingId, sender: nil)
    }
    
    func rejectAndWriteToFirebase(){
        
        switch offer!.offerStatus.rawValue{
        case Constants.offerStatus.active:
            //if rejected when required a confirmation
            let pathForTransposeOfAcceptedOffer = "/transposeOfacceptedOffer/\(offer!.firebaseId)/\(offer!.bidId!)"
            let pathToUpdateStatus = "/Users/\(appUser.firebaseId)/Bid/\(offer!.bidId!)/offer/\(Constants.offer.offerStatus)"
            let updates: [String: Any] = [pathForTransposeOfAcceptedOffer: NSNull(), pathToUpdateStatus: Constants.offerStatus.nonActive]
            rootReference.updateChildValues(updates)
        case Constants.offerStatus.counterOffer:
            //if rejected when required a confirmation
            let pathForTransposeOfAcceptedOffer = "/counterOffer/\(offer!.firebaseId)/\(offer!.bidId!)"
            let pathToUpdateStatus = "/Users/\(appUser.firebaseId)/Bid/\(offer!.bidId!)/offer/\(Constants.offer.offerStatus)"
            let updates: [String: Any] = [pathForTransposeOfAcceptedOffer: NSNull(), pathToUpdateStatus: Constants.offerStatus.nonActive]
            rootReference.updateChildValues(updates)
            //if there is a counterOfferOther 
            if offer!.firebaseId != appUser.firebaseId{
                let pathForCounterOfferOther = "/counterOffer/\(appUser.firebaseId)/\(offer!.bidId!)"
                rootReference.updateChildValues([pathForCounterOfferOther: NSNull()])
            }
            
        default:
            print("how did we get here ")
        }
        
        let pathForTransposeOfAcceptedOffer = "/transposeOfacceptedOffer/\(offer!.firebaseId)/\(offer!.bidId!)"
        let pathToUpdateStatus = "/Users/\(appUser.firebaseId)/Bid/\(offer!.bidId!)/offer/\(Constants.offer.offerStatus)"
        let pathForPublicInfo = "bidIdStatus/\(offer!.bidId!)"
        let updates: [String: Any] = [pathForTransposeOfAcceptedOffer: NSNull(), pathToUpdateStatus: Constants.offerStatus.nonActive, pathForPublicInfo: NSNull()]
        rootReference.updateChildValues(updates)
        
    }
   
   
    
    func sendNotificationOfRejection(){
        // Create a reference to the file to download when the notification is recived
        let imageReference = FIRStorage.storage().reference().child("ProfilePictures/\(appUser.firebaseId).jpg")
        var urlString: String? = nil
        imageReference.downloadURL{ aUrl, error in
            
            if let error = error {
                // Handle any errors
                print("there was an error \(error)")
            }else{
                urlString = "\(aUrl!)"
                
                var contentsDictionary = [String: String]()
                var headingsDictionary = [String: String]()
                var spanishMessage : String = ""
                var portugueseMessage: String = ""
                var spanishTitle: String = ""
                var portugueseTitle: String = ""
                
                //we always need to include a message in English
                contentsDictionary = ["en": "Continue into MonEx to search for other offers or create a new offer"]
                spanishMessage = "Continue en MonEx, busque otras ofertas o cree una nueva oferta"
                portugueseMessage = "Continue na MonEx para procurar outras ofertas ou criar uma"
                //The heading text
                headingsDictionary = ["en": "\(self.appUser.name) did not approved of your request"]
                spanishTitle = "\(self.appUser.name) no aprobo su solicitud"
                portugueseTitle = "\(self.appUser.name) não aprovar o seu pedido"
                
                contentsDictionary["es"] = spanishMessage
                contentsDictionary["pt"] = portugueseMessage
                headingsDictionary["es"] = spanishTitle
                headingsDictionary["pt"] = portugueseTitle
                
                var subTitileDictionary = ["en": "Not approved"]
                let spansihSubTitle = "Rechazada"
                let portugueseSubTitle = "Rejeitada"
                subTitileDictionary["es"] = spansihSubTitle
                subTitileDictionary["pt"] = portugueseSubTitle
                
                self.offerNewStatusRawValue = Constants.offerStatus.nonActive
                
                //we use one signal to push the notification
                OneSignal.postNotification(["contents": contentsDictionary, "headings":headingsDictionary,"subtitle":subTitileDictionary,"include_player_ids": ["\(self.offer!.oneSignalId)"], "content_available": true, "mutable_content": true, "data":["imageUrl": urlString, "name": "\(self.appUser.name)", "distance": self.distanceLabel.text, "bidId": self.offer?.bidId!, Constants.offer.offerStatus: self.offerNewStatusRawValue, Constants.offer.firebaseId: self.appUser.firebaseId],"ios_category": "acceptOffer"], onSuccess: { (dic) in
                    
                    //we dismiss the AcceptedViewController
                    self.dismissAcceptViewController(goToMyBids: false)
                    
                    print("THERE WAS NO ERROR")
                }, onFailure: { (Error) in
                    print("THERE WAS AN EROOR \(Error!)")
                })
            }
        }
    }

    
    func dismissAcceptViewController(goToMyBids: Bool){
        DispatchQueue.main.async {
            let _ = self.navigationController?.popToRootViewController(animated: true)
            let browseViewController = self.navigationController?.viewControllers.first as? BrowseOffersViewController
            browseViewController?.dismiss(animated: true, completion: {
            
                if goToMyBids{
                    let inquiryViewController = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController as? InquiryViewController
                    inquiryViewController?.myBids((inquiryViewController?.navigationBar.topItem?.rightBarButtonItems?.first)!)
                    
                }
            })
        }
    }
    
    func deleteInfo(bidId:String){
        rootReference.child("bidIdStatus/\(bidId)").observeSingleEvent(of: .value, with:{ (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else{
                return
            }
            guard let lastOneToWrite = dictionary[Constants.publicBidInfo.lastOneToWrite] as? String else{
                return
            }
            
            // if the last one to write was the user then everything that was created for the bid should be erased
            if lastOneToWrite == self.appUser.firebaseId{
                
                self.appUser.getOtherOffer(bidId: (bidId)){ otherOffer in
                    
                    guard let otherOffer = otherOffer else{
                        return
                    }
                    
                    let pathForBidStatus = "/bidIdStatus/\(bidId)" // set to Null
                    let pathForTranspose = "/transposeOfacceptedOffer/\(otherOffer.firebaseIdOther!)/\(bidId)"//set to null
                    let pathForBidLocation = "/offerBidsLocation/\(bidId)/lastOfferInBid/\(Constants.offer.offerStatus)" //update to non active
                    let pathToMyBids = "/Users/\(self.appUser.firebaseId)/Bid/\(bidId)" //set to null
                    
                    self.rootReference.updateChildValues([pathForBidStatus: NSNull(), pathForBidLocation: Constants.offerStatus.nonActive, pathForTranspose: NSNull(), pathToMyBids: NSNull()])
                }
            }
            
            print("we are here")
        })
    }

    
    // we use this function to write the offer dictionary and the transpose dictionary into firebase once the offer is accepted, if the offer is confirmed we use this function to update form accepted to confirmed the entires in the dictionaries, likeswise in the other cases
    func acceptOfferAndWriteToFirebase(){
        //we write the ooferDictionary to firbase, bids path
        var offerDictionary : [String:String] = [:]
        offerDictionary = offer!.getDictionaryFromOffer()
        //we change the status acordingly 
        switch currentStatus{
        case .acceptOffer:
            offerDictionary[Constants.offer.offerStatus] = Constants.offerStatus.active
            offerNewStatusRawValue = Constants.offerStatus.active
        case .waitingForConfirmation:
            print("waiting for confirmation no action taken here")
        case .offerAcceptedNeedConfirmation:
            offerDictionary[Constants.offer.offerStatus] = Constants.offerStatus.approved
            offerNewStatusRawValue = Constants.offerStatus.approved
        case .counterOfferConfirmation:
            offerDictionary[Constants.offer.offerStatus] = Constants.offerStatus.counterOfferApproved
            offerNewStatusRawValue = Constants.offerStatus.counterOfferApproved
        case .offerConfirmed:
            print("offer confirmed ")
        }
        
        //we update the public bid info 
        var newInfoDictionary = [String: Any]()
        newInfoDictionary[Constants.publicBidInfo.authorOfTheBid] = offer?.firebaseId
        newInfoDictionary[Constants.publicBidInfo.bidId] = offer?.bidId
        newInfoDictionary[Constants.publicBidInfo.lastOneToWrite] = appUser.firebaseId
        newInfoDictionary[Constants.publicBidInfo.otherUser] = appUser.firebaseId//it will not update unless this info is non existent
        newInfoDictionary[Constants.publicBidInfo.status] = offerNewStatusRawValue
        let now = Date()
        let timeStamp = now.timeIntervalSince1970
        newInfoDictionary[Constants.publicBidInfo.timeStamp] = timeStamp
        
        guard let newPublicInfo = PublicBidInfo(dictionary: newInfoDictionary) else{
            return
        }
        

        //we use this function to write the transposeOfferToFirebase
        //since we are working with the transpose we mean "sell changed to buy", and to the info of the buyer instead of info of the seller
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        var transposeOfferDictionary : [String:String] = [:]
        transposeOfferDictionary[Constants.offer.buyCurrencyCode] = offer?.sellCurrencyCode
        transposeOfferDictionary[Constants.offer.buyQuantity] = offer?.sellQuantity
        transposeOfferDictionary[Constants.offer.dateCreated] = dateFormatter.string(from: now)
        transposeOfferDictionary[Constants.offer.firebaseId] = appUser.firebaseId
        transposeOfferDictionary[Constants.offer.imageUrl] = appUser.imageUrl
        switch currentStatus{
        case .acceptOffer:
            transposeOfferDictionary[Constants.offer.offerStatus] = Constants.offerStatus.active
        case .offerAcceptedNeedConfirmation, .counterOfferConfirmation:
            transposeOfferDictionary[Constants.offer.offerStatus] = Constants.offerStatus.approved
        case .waitingForConfirmation:
            print("waiting for confirmation")
        case .offerConfirmed:
            print("offer confirmed ")
        }
       
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
        
        transposeOfferDictionary[Constants.offerBidLocation.longitude] = "\(appUser.longitude!)"
        transposeOfferDictionary[Constants.offerBidLocation.latitude] = "\(appUser.latitude!)"
        
        appUser.updateBidStatus(newInfo: newPublicInfo, completion: { (error, comitted, snapshot) in
            
            guard error == nil else{
                //TODO display an error tu the user
                print("there is an error with the update of the status ")
                return
            }
            
            self.completion(transposeOfferDictionary: transposeOfferDictionary, offerDictionary: offerDictionary)
        })
        
    }
    
    func completion(transposeOfferDictionary:[String: String], offerDictionary: [String:String]){
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("The offer was not confirmed", comment: "The offer was accepted")
        content.subtitle = String(format: NSLocalizedString("%@ did not take action", comment: "%@name did not take action"), arguments: ["\(offerDictionary[Constants.offer.name]!)"])
        content.body = NSLocalizedString("Five minutes have passed and the offer was not confirmed, please search for other offers", comment: "Five minutes have passed and the offer was not confirmed, please search for other offers")
        
        
        content.categoryIdentifier = "acceptOffer"
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(Constants.timeToRespond.timeToRespond), repeats: false)
        let requestIdentifier = Constants.notification.fiveMinutesNotification + " " + "\(offer!.bidId!)"

        
        switch currentStatus{
        case .acceptOffer:
            //write it to accept it offer
            var pathForTransposeOfAcceptedOffer = "/transposeOfacceptedOffer/\(offer!.firebaseId)/\(offer!.bidId!)"
            let acceptedfferAutoId = rootReference.child(pathForTransposeOfAcceptedOffer).childByAutoId().key
            pathForTransposeOfAcceptedOffer = pathForTransposeOfAcceptedOffer + "/\(acceptedfferAutoId)"
            let pathToOffersBid = "/Users/\(appUser.firebaseId)/Bid/\(offer!.bidId!)/offer"
            rootReference.updateChildValues([pathForTransposeOfAcceptedOffer: transposeOfferDictionary, pathToOffersBid: offerDictionary])
            let imageReference = FIRStorage.storage().reference().child("ProfilePictures/\(offer!.firebaseId).jpg")
            var urlString: String? = nil
            imageReference.downloadURL{ aUrl, error in
                
                if let error = error {
                    // Handle any errors
                    print("there was an error \(error)")
                } else {
                    urlString = "\(aUrl!)"
                }
                
                //send the 5 minute notification
                content.userInfo = [Constants.notification.data:[Constants.notification.imageUrl: urlString , Constants.notification.name: offerDictionary[Constants.offer.name]!, Constants.notification.counterOfferPath: pathForTransposeOfAcceptedOffer, Constants.notification.bidId: self.offer!.bidId!]]
                let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
                    // handle error
                })
            }
            
            
            
            //save the information of the other in core Data 
            context?.perform{
                let _ = OtherOffer(bidId: self.offer!.bidId!, firebaseIdOther: self.offer!.firebaseId, imageUrlOfOther: self.offer!.imageUrl, name: self.offer!.name, context: (self.context)!)
            }
            
        case .offerAcceptedNeedConfirmation:
            //update the user bid to approved
            let pathToUpdateStatus = "/Users/\(appUser.firebaseId)/Bid/\(offer!.bidId!)/offer/\(Constants.offer.offerStatus)"
            rootReference.updateChildValues([pathToUpdateStatus: Constants.offerStatus.approved])
        case .waitingForConfirmation:
            print("waiting for confirmation")
        case .counterOfferConfirmation:
            //update the user bid to approved
            let pathToUpdateStatus = "/Users/\(appUser.firebaseId)/Bid/\(offer!.bidId!)/offer/\(Constants.offer.offerStatus)"
            rootReference.updateChildValues([pathToUpdateStatus: Constants.offerStatus.counterOfferApproved])
            print("counterOffer")
        case .offerConfirmed:
            print("offer confirmed ")
        }

    }
    
    func configureStorage() {
        //configure storage using your firebase storage
        storageReference = FIRStorage.storage().reference()
    }
    
    func sendNotificationOfAcceptence(){
        // Create a reference to the file to download when the notification is recived
        let imageReference = FIRStorage.storage().reference().child("ProfilePictures/\(appUser.firebaseId).jpg")
        var urlString: String? = nil
        imageReference.downloadURL{ aUrl, error in
            
            if let error = error {
                // Handle any errors
                print("there was an error \(error)")
            } else {
                urlString = "\(aUrl!)"
                
                var contentsDictionary = [String: String]()
                var headingsDictionary = [String: String]()
                var spanishMessage : String = ""
                var portugueseMessage: String = ""
                var spanishTitle: String = ""
                var portugueseTitle: String = ""
                switch self.currentStatus{
                case .acceptOffer:
                    //we always need to include a message in English
                    contentsDictionary = ["en": "Go to My bids inside MonEx to take action, if you take no action the request will be dismissed automatically after 5 min"]
                    spanishMessage = "Dentro de MonEx seleciona Mis subastas y elige una opcion, si no eliges ninguna opcion la propuesta sera rechazada automaticamente despues de 5 min"
                    portugueseMessage = "Dentro na MonEx seleçione Mias Subastas y ecolia uma opçao, si voce nao elige niguma opçao a propuesta sera descartada automaticamente a pos 5 min"
                    //The heading text
                    headingsDictionary = ["en": "\(self.appUser.name) is interested in your offer"]
                    spanishTitle = "\(self.appUser.name) esta interesado en su oferta"
                    portugueseTitle = "\(self.appUser.name) esta interessado em sua oferta"
                    
                case .offerAcceptedNeedConfirmation, .counterOfferConfirmation:
                    //we always need to include a message in English
                    contentsDictionary = ["en": "You are able to send messages to \(self.appUser.name) through MonEx and the map will show your respective locations"]
                    spanishMessage = "Esta autorizado para mandar mensajes a \(self.appUser.name) via MonEx y el mapa mostrara sus respectivas posisiones"
                    portugueseMessage = "Voce está autorizado a enviar mensagens via Monex  pra \(self.appUser.name) o mapa irá mostrar suas respectivas posições "
                    
                    //The heading text
                    headingsDictionary = ["en": "\(self.appUser.name) has confirmed"]
                    spanishTitle = "\(self.appUser.name) ha confirmado"
                    portugueseTitle = "\(self.appUser.name) confirmo"
                case .waitingForConfirmation:
                    print("waiting for confirmation")

                case .offerConfirmed:
                    print("offer confirmed ")
                }
                
                contentsDictionary["es"] = spanishMessage
                contentsDictionary["pt"] = portugueseMessage
                headingsDictionary["es"] = spanishTitle
                headingsDictionary["pt"] = portugueseTitle
                
                var subTitileDictionary = ["en": "Continue with the transaction on MonEx"]
                let spansihSubTitle = "Continue con la transaccion dentro de MonEx"
                let portugueseSubTitle = "Continue com a transação no MonEx"
                subTitileDictionary["es"] = spansihSubTitle
                subTitileDictionary["pt"] = portugueseSubTitle
    
                //we use one signal to push the notification
                OneSignal.postNotification(["contents": contentsDictionary, "headings":headingsDictionary,"subtitle":subTitileDictionary,"include_player_ids": ["\(self.offer!.oneSignalId)"], "content_available": true, "mutable_content": true, "data":["imageUrl": urlString, "name": "\(self.appUser.name)", "distance": self.distanceLabel.text, "bidId": self.offer?.bidId!, Constants.offer.offerStatus: self.offerNewStatusRawValue, Constants.offer.firebaseId: self.appUser.firebaseId],"ios_category": "acceptOffer"], onSuccess: { (dic) in
                    
                    switch self.currentStatus{
                    case .acceptOffer:
                        self.currentStatus = .waitingForConfirmation
                        self.dismissAcceptViewController(goToMyBids: true)
                    case .waitingForConfirmation:
                        print("waiting for confirmation")
                    //sendNotificationOfAcceptence()
                    case .offerAcceptedNeedConfirmation:
                        self.currentStatus = .offerConfirmed
                    case .counterOfferConfirmation:
                        self.currentStatus = .offerConfirmed
                        print("conterofferConfirmation")
                    case .offerConfirmed:
                        print("offer confirmed ")
                    }
                    
                    //we re set all labels in case something changed
                    self.setAlltheLabels()
                    
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
            guard let latitude = offer?.latitude, let longitude = offer?.longitude else{
                return
            }
            
            let sellerLocation = CLLocation(latitude: latitude , longitude: longitude)
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
        
        switch currentStatus{
        case .acceptOffer:
            acceptButton.isHidden = false
            rejectButton.isHidden = true
            counterOfferButton.isHidden = false
        case .offerAcceptedNeedConfirmation:
            acceptButton.isHidden = false
            rejectButton.isHidden = false
            counterOfferButton.isHidden = true
        case .waitingForConfirmation:
            acceptButton.isHidden = false
            acceptButton.setTitle(NSLocalizedString("Waiting for the confirmation...", comment: "Waiting for the confirmation"), for: .normal)
            acceptButton.isEnabled = false
            rejectButton.isHidden = true
            counterOfferButton.isHidden = true
        case .counterOfferConfirmation:
            acceptButton.isHidden = false
            rejectButton.isHidden = false
            counterOfferButton.isHidden = false
        case .offerConfirmed:
            acceptButton.isHidden = false
            acceptButton.setTitle(NSLocalizedString("Continue", comment: "Continue"), for: .normal)
            rejectButton.isHidden = true
            counterOfferButton.isHidden = true
        }

    }
    
    //errors
    func showExpiredAlert(){
        let alert = UIAlertController(title: NSLocalizedString("The request has expired", comment: "The request has expired"), message: "The request that have not been approved expire after 5 min", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler:{ (alert) in
            self.dismissAcceptViewController(goToMyBids: true)
        })
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func formatterByCode(_ currencyCode: String)-> NumberFormatter{
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
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
            messagesViewController?.acceptOfferViewController = self
        }
        
        if segue.identifier == counterOfferBidId{
            let offerViewController = segue.destination as! OfferViewController            
            offerViewController.user = FIRAuth.auth()?.currentUser
            offerViewController.offer = offer
            offerViewController.isCounterOffer = true
            offerViewController.distanceFromOffer = distanceLabel.text
            offerViewController.acceptOfferViewController = self 
        }
        
        if segue.identifier == ratingId{
            let ratingViewController = segue.destination as! RatingViewController
            ratingViewController.acceptViewController = self
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
        return pinView
    }
    
}


