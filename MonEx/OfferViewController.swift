//
//  OfferViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Firebase
import UIKit
//import FirebaseAuthUI
import OneSignal
import CoreData

class OfferViewController: UIViewController {
    
    var rootReference:FIRDatabaseReference!
    var acceptOfferViewController: AcceptOfferViewController?
    var keyboardOnScreen = false
    var popUpOriginy: CGFloat = 0
    var currencyRatio: String?
    var quantitySell: String?
    var quantityBuy: String?
    var yahooRate: Float?
    var yahooCurrencyRatio: String?
    var userRate: Float?
    var sellLastEdit = false
    var buyLastEdit = false
    var formatterSell: NumberFormatter?
    var formatterBuy: NumberFormatter?
    var user: FIRUser?
    let appUser = AppUser.sharedInstance
    var isCounterOffer: Bool = false 
    var offer: Offer? = nil
    var distanceFromOffer: String? // we use this in the counteroffer only
    var context : NSManagedObjectContext? = nil
    let per = NSLocalizedString(" per 1 ", comment: " per 1 ")
    var inquiryViewController: InquiryViewController?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        preparationForCounterOffer()
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var sellCurrencyLabel: UILabel!
    @IBOutlet weak var buyCurrencyLabel: UILabel!
    @IBOutlet weak var currencyRatioLabel: UILabel!
    @IBOutlet weak var quantitySellTextField: UITextField!
    @IBOutlet weak var quantityBuyTextField: UITextField!
    @IBOutlet weak var rateTextField: UITextField!
    @IBOutlet weak var offerDescriptionLabel: UILabel!
    @IBOutlet weak var makeOfferButton: UIButton!
    @IBOutlet weak var sellOfferBuyCounterOffer: UILabel!
    @IBOutlet weak var buyOfferSellCounterOffer: UILabel!
    
    @IBOutlet weak var OKView: UIView!
    
    @IBOutlet weak var okLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //if is a counteroffer we need different parameters and we call the prepare for counter offer
        preparationForCounterOffer()

        //set a reference to the database 
        rootReference = FIRDatabase.database().reference()
        //set the labels with info coming form the Inquiry View Controller or form the offer of the counteroffer
        sellCurrencyLabel.text = formatterSell?.currencyCode
        buyCurrencyLabel.text = formatterBuy?.currencyCode
        currencyRatioLabel.text = currencyRatio
        
        
        if isCounterOffer{
            formatterSell?.currencySymbol = ""
            formatterBuy?.currencySymbol = ""
        }
        
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let stack = appDelegate.stack
            self.context = stack?.context
        }
        
        
        //set the labels depending on whether is a counterOffer or not
        sellOfferBuyCounterOffer.text = !isCounterOffer ? NSLocalizedString("SELL:", comment: "SELL:") : NSLocalizedString("BUY:", comment: "BUY:")
        buyOfferSellCounterOffer.text = !isCounterOffer ? NSLocalizedString("BUY:", comment: "BUY:") : NSLocalizedString("SELL:", comment: "SELL:")
        
       
        //set the decimal part of the sell and buy text fields
        if let decimalPartSell = formatterSell?.number(from: quantitySell!) as? Float{
            let decimalPartSell = Int(round(decimalPartSell))
            formatterSell?.currencySymbol = ""
            //we set the entries on the text fields with out the symbol, and use formatter to preserve the comas and punctuations we want to be integers
            quantitySellTextField.text =  formatterSell?.string(from: decimalPartSell as NSNumber)
        }else{
            quantitySellTextField.text = ""
        }
        
        if let decimalPartBuy = formatterBuy?.number(from: quantityBuy!) as? Float{
            let decimalPartBuy = Int(round(decimalPartBuy))
            formatterBuy?.currencySymbol = ""
            //we set the entries on the text fields with out the symbol, and use formatter to preserve the punctuation
            quantityBuyTextField.text = formatterBuy?.string(from: decimalPartBuy as NSNumber)
        }else{
            quantityBuyTextField.text = ""
        }
        
        rateTextField.text =  String(format: "%.2f", userRate!)
        updateOffer()
    
        //placeholders 
        quantitySellTextField.placeholder = NSLocalizedString("Qty", comment: "Qty: place holder in the offerViewController")
        quantityBuyTextField.placeholder = NSLocalizedString("Qty", comment: "Qty: place holder in the offerViewController")
        
        //Do some styling for the popUpView
        popUpView.layer.cornerRadius = 10
        //make the background clear 
        view.backgroundColor = UIColor.clear
        // round style for the button 
        makeOfferButton.layer.cornerRadius = 10 
        
        //we style the ok label and viw
        okLabel.text = NSLocalizedString("Success! \n Offer posted online", comment: "Offer posted online")
        OKView.isHidden = true
        OKView.layer.cornerRadius = 10

        
        
        //Add a gesture recognizer with an acction so that the Offer View Controller dismisses 
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeOffer))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        //set the delegats for text fields 
        quantitySellTextField.delegate = self
        quantityBuyTextField.delegate = self
        rateTextField.delegate = self
        
        //set the keyboards 
        quantitySellTextField.keyboardType = .numberPad
        quantityBuyTextField.keyboardType = .numberPad
        rateTextField.keyboardType = .decimalPad
        addDoneButtonOnKeyboard()
        
        // subscribe to notifications to update the Description label 
        subscribeToNotification(NSNotification.Name.UITextFieldTextDidChange.rawValue, selector: #selector(updateOffer))
        //subscibe to notifications in order to move the view up or down
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: #selector(keyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: #selector(keyboardDidHide))

    }
    
    
    
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        popUpOriginy = popUpView.frame.origin.y
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
 
    @IBAction func makeOffer(_ sender: Any) {
        //post it to the data base
        var dictionary = [String: String]()
        guard quantitySellTextField.text! != "" else{
            missingValue()
            return
        }
        
        //TODO: make sure there is no active offers before activating this one
        dictionary[Constants.offer.isActive] = "false"
        dictionary[Constants.offer.sellQuantity] = !isCounterOffer ? quantitySellTextField.text! : quantityBuyTextField.text!
        guard quantityBuyTextField.text! != "" else{
            missingValue()
            return
        }
        //we write it differntly depending on whether is an offer of a counterOffer
        dictionary[Constants.offer.buyQuantity] = !isCounterOffer ? quantityBuyTextField.text! : quantitySellTextField.text!
        dictionary[Constants.offer.sellCurrencyCode] = !isCounterOffer ? sellCurrencyLabel.text : buyCurrencyLabel.text
        dictionary[Constants.offer.buyCurrencyCode] = !isCounterOffer ? buyCurrencyLabel.text : sellCurrencyLabel.text
        guard let yahooRate = yahooRate else{
            return
        }
        dictionary[Constants.offer.yahooRate] = "\(yahooRate)"
        dictionary[Constants.offer.yahooCurrencyRatio] = "\(yahooRate) " + yahooCurrencyRatio!
        
        guard rateTextField.text! != "" else{
            missingValue()
            return
        }
        dictionary[Constants.offer.userRate] = rateTextField.text!
        dictionary[Constants.offer.rateCurrencyRatio] = rateTextField.text! + " " + currencyRatio!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let now = Date()
        dictionary[Constants.offer.dateCreated] = dateFormatter.string(from: now)
        dictionary[Constants.offer.timeStamp] = "\(now.timeIntervalSince1970)"
        dictionary[Constants.offer.imageUrl] = appUser.imageUrl
        dictionary[Constants.offer.name] = appUser.name
        dictionary[Constants.offer.firebaseId] = appUser.firebaseId
        dictionary[Constants.offer.offerStatus] = Constants.offerStatus.nonActive
        
        
        
        guard let latitude = appUser.latitude, let longitude = appUser.longitude else{
            alertForLocation()
            
            return
        }
        
        dictionary[Constants.offerBidLocation.latitude] = "\(latitude)"
        dictionary[Constants.offerBidLocation.longitude] = "\(longitude)"
        
        
        
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let oneSignalId = status.subscriptionStatus.userId
        dictionary[Constants.offer.oneSignalId] = oneSignalId

        
        guard appUser.name != "" else{
            missingProfile()
            return
        }
        
        guard appUser.imageUrl != "" else{
            missingProfilePicture()
            return
        }
        
        //make sure user is no nil
        if let user = user{
          // if is an offer
          if !isCounterOffer{
            
              //get reference to the offerbid
              let pathBid = "Users/\(user.uid)/Bid"
              let bidReference = rootReference.child(pathBid).childByAutoId()
              let bidId = bidReference.key
              
              //add the bidId to the array of bidId
              appUser.bidIds.append(bidId)
            
              //we create the offerbid location and post it to firebase
              appUser.getLocation(viewController: self, highAccuracy: false)
              var data = [String: Any]()
              guard let latitude = appUser.latitude, let longitude = appUser.longitude else{
                  unabeleToLocate()
                  return
              }
              data[Constants.offerBidLocation.latitude] = latitude
              data[Constants.offerBidLocation.longitude] = longitude
              data[Constants.offerBidLocation.lastOfferInBid] = dictionary
            
              let pathOfferBidUserId = "locations/\(bidId)/\(appUser.firebaseId)"
              appUser.writeToFirebase(withPath: pathOfferBidUserId)
              let latLonValues = [Constants.offerBidLocation.latitude: latitude, Constants.offerBidLocation.longitude: longitude]
              //the offerBidsLocation are ordered by bidId
              rootReference.updateChildValues(["/\(pathBid)/\(bidId)/offer": dictionary,"/\(Constants.offerBidLocation.offerBidsLocation)/\(bidId)": data, pathOfferBidUserId: latLonValues], withCompletionBlock: { (error, reference) in
                  if error != nil {
                      print("there was an error \(error!)")
                  }
              })
            
               DispatchQueue.main.async {
                self.OKView.isHidden = false
                UIView.animateKeyframes(withDuration: 3, delay: 0, options: .calculationModeCubic, animations: {
                    
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/12, animations: {
                        self.popUpView.center.y = -self.view.bounds.size.height
                        self.popUpView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    })
                    
                    UIView.addKeyframe(withRelativeStartTime: 1/12, relativeDuration: 1/12, animations: {
                        self.OKView.center.y = self.view.center.y - 20
                    })
                    
                    UIView.addKeyframe(withRelativeStartTime: 1/6, relativeDuration: 5/6, animations: {
                    
                       //we have no animations here we just allow the presentation of the message for 1/3 of a second
                    })
                    
                }, completion: { finished in
                    //we hide the popUpView
                    self.popUpView.isHidden = true
                    
                    //one is finished we dismiss the controller
                    if finished{
                        self.dismiss(animated: true, completion: nil)
                        if let myBidsButton = self.inquiryViewController?.myBidsButton{
                            self.inquiryViewController?.myBids(myBidsButton)
                        }
                    }
                })
                
               }
            
             }else{
             //if is a counter offer
             guard let offer = offer else{
                 //TODO: handle errors
                 return
             }
            
            
            
             //for a counteroffer we change the info
             dictionary[Constants.offer.offerStatus] = Constants.offerStatus.counterOffer
             dictionary[Constants.offer.yahooRate] = "\(1/yahooRate)"
             dictionary[Constants.offer.yahooCurrencyRatio] = "\(1/yahooRate) " + offer.sellCurrencyCode + per + offer.buyCurrencyCode
            
            
             var pathForCounterOffer = "/counterOffer/\(offer.firebaseId)/\(offer.bidId!)"
             var pathForCounterOfferMyId = "/counterOffer/\(appUser.firebaseId)/\(offer.bidId!)"
             let counterofferAutoId = rootReference.child(pathForCounterOffer).childByAutoId().key
             let myCounterofferAutoId = rootReference.child(pathForCounterOfferMyId).childByAutoId().key
             pathForCounterOffer = pathForCounterOffer + "/\(counterofferAutoId)"
             pathForCounterOfferMyId = pathForCounterOfferMyId + "/\(myCounterofferAutoId)"
             let pathToMyCounterOffers = "/Users/\(appUser.firebaseId)/Bid/\(offer.bidId!)/offer"
            
            
             //we use aDictionary to create the transpose of the counteroffer 
             var aDictionary = dictionary
             aDictionary[Constants.offer.firebaseId] = offer.firebaseId
             aDictionary[Constants.offer.oneSignalId] = offer.oneSignalId
             aDictionary[Constants.offer.imageUrl] = offer.imageUrl
             aDictionary[Constants.offer.name] = offer.name
             aDictionary[Constants.offer.buyCurrencyCode] = dictionary[Constants.offer.sellCurrencyCode]
             aDictionary[Constants.offer.buyQuantity] = dictionary[Constants.offer.sellQuantity]
             aDictionary[Constants.offer.sellCurrencyCode] = dictionary[Constants.offer.buyCurrencyCode]
             aDictionary[Constants.offer.sellQuantity] = dictionary[Constants.offer.buyQuantity]
            
             //rootReference.child(pathForCounterOffer).childByAutoId().setValue(dictionary)
             rootReference.updateChildValues([pathForCounterOffer: dictionary, pathToMyCounterOffers: aDictionary, pathForCounterOfferMyId: dictionary])
            
             // Create a reference to the file you want to send
             let imageReference = FIRStorage.storage().reference().child("ProfilePictures/\(appUser.firebaseId).jpg")
            
             //we update the public bid info
             var newInfoDictionary = [String: Any]()
             newInfoDictionary[Constants.publicBidInfo.authorOfTheBid] = offer.firebaseId
             newInfoDictionary[Constants.publicBidInfo.bidId] = offer.bidId
             newInfoDictionary[Constants.publicBidInfo.lastOneToWrite] = appUser.firebaseId //it will not update to 0 unless there is no info
             newInfoDictionary[Constants.publicBidInfo.otherUser] = appUser.firebaseId//it will not update unless this info is non existent
             newInfoDictionary[Constants.publicBidInfo.status] = Constants.offerStatus.counterOffer
             let now = Date()
             let timeStamp = now.timeIntervalSince1970
             newInfoDictionary[Constants.publicBidInfo.timeStamp] = timeStamp
            
             guard let newPublicInfo = PublicBidInfo(dictionary: newInfoDictionary) else{
                return
             }
            
             appUser.updateBidStatus(newInfo: newPublicInfo, completion: { (error, comitted, snapshot) in
                
                guard error == nil else{
                    //TODO display an error tu the user
                    print("there is an error with the update of the status \(error!)")
                    return
                }
                
                imageReference.downloadURL{ aUrl, error in
    
                    if let error = error {
                        // Handle any errors
                        print("there was an error \(error)")
                    } else {
                        
                        let urlString = "\(aUrl!)"
                        
                        let content = UNMutableNotificationContent()
                        content.title = NSLocalizedString("The offer was not confirmed", comment: "The offer was accepted")
                        content.subtitle = String(format: NSLocalizedString("%@ did not take action", comment: "%@name did not take action"), arguments: ["\(offer.name)"])
                        content.body = NSLocalizedString("Five minutes have passed and the counteroffer was not confirmed, please search for other offers", comment: "Five minutes have passed and the counteroffer was not confirmed, please search for other offers")
                        
                        
                        content.categoryIdentifier = "acceptOffer"
                        content.sound = UNNotificationSound.default()
                        
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(Constants.timeToRespond.timeToRespond), repeats: false)
                        let requestIdentifier = Constants.notification.fiveMinutesNotification + " " + "\(offer.bidId!)"
                        content.userInfo = [Constants.notification.data:[Constants.notification.imageUrl: urlString , Constants.notification.name: offer.name, Constants.notification.counterOfferPath: pathForCounterOffer, Constants.notification.bidId: offer.bidId!]]
                        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
                            // handle error
                        })

                        //save the information of the other in core Data
                        if self.offer!.firebaseId != self.appUser.firebaseId && !self.offer!.imageUrl.contains(self.appUser.firebaseId){
                            self.context?.perform{
                                let _ = OtherOffer(bidId: self.offer!.bidId!, firebaseIdOther: self.offer!.firebaseId, imageUrlOfOther: self.offer!.imageUrl, name: self.offer!.name, context: (self.context)!)
                            }
                        }

                        //we always need to include a message in English
                        var contentsDictionary = ["en": "Go to My bids inside MonEx to take action, if you take no action the request will be dismissed automatically after 5 min"]
                        let spanishMessage = "Dentro de MonEx seleciona Mis subastas y elige una opcion, si no eliges ninguna opcion la propuesta sera rechazada automaticamente despues de 5 min"
                        let portugueseMessage = "Dentro na MonEx seleçione Mias Subastas y ecolia uma opçao, si voce nao elige niguma opçao a propuesta sera descartada automaticamente a pos 5 min"
                        contentsDictionary["es"] = spanishMessage
                        contentsDictionary["pt"] = portugueseMessage
                        
                        var headingsDictionary = ["en": "\(self.appUser.name) send you a counteroffer"]
                        let spanishTitle = "\(self.appUser.name) te mando una contraoferta"
                        let portugueseTitle = "\(self.appUser.name) envio uma contraoferta"
                        headingsDictionary["es"] = spanishTitle
                        headingsDictionary["pt"] = portugueseTitle
                        
                        var subTitileDictionary = ["en": "Continue with the transaction on MonEx"]
                        let spansihSubTitle = "Continue con la transaccion dentro de MonEx"
                        let portugueseSubTitle = "Continue com a transação no MonEx"
                        subTitileDictionary["es"] = spansihSubTitle
                        subTitileDictionary["pt"] = portugueseSubTitle
                        
                        //we use one signal to push the notification
                        OneSignal.postNotification(["contents": contentsDictionary, "headings":headingsDictionary,"subtitle":subTitileDictionary,"include_player_ids": ["\(self.offer!.oneSignalId)"], "content_available": true, "mutable_content": true, "data": ["imageUrl": urlString, "name": "\(self.appUser.name)", "distance": self.distanceFromOffer!, "counterOfferPath":pathForCounterOffer, "bidId": self.offer?.bidId!, Constants.offer.offerStatus: Constants.offerStatus.counterOffer, Constants.offer.firebaseId: self.appUser.firebaseId],"ios_category": "acceptOffer"], onSuccess: { (dic) in
                            print("THERE WAS NO ERROR")
                        }, onFailure: { (Error) in
                            print("THERE WAS AN EROOR \(Error!)")
                        })
                    }
                 }
                
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                    self.acceptOfferViewController?.dismissAcceptViewController(goToMyBids: true)
                }
             })
            
            }
        }
        
    }
    
    
    @IBAction func closeOffer(_ sender: Any) {
       dismiss(animated: true, completion: nil)
    }
    
    func formatterByCode(_ currencyCode: String)-> NumberFormatter{
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        
        return formatter
    }
    
    func alertForLocation(){
        let alert = UIAlertController(title: NSLocalizedString("Unable to locate you", comment: "Unable to locate you"), message: NSLocalizedString("The device can not point out your location, try to get better signal and try again.", comment: "The device can not point out your location, try to get better signal and try again.") , preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func preparationForCounterOffer(){
        //if is a counter offer then we have an offer
        if isCounterOffer{
            makeOfferButton.setTitle(NSLocalizedString("Make Counteroffer", comment: "Make Counteroffer: button title"), for: .normal)
            makeOfferButton.backgroundColor = Constants.color.greenLogoColor
            self.offer = offer!
            //since is a counterOffer we need to swap the roles of sell and buy for the formatter
            formatterSell = formatterByCode((offer?.sellCurrencyCode)!)
            formatterBuy = formatterByCode((offer?.buyCurrencyCode)!)
            quantitySell = offer?.sellQuantity
            quantityBuy = offer?.buyQuantity
            yahooRate = Float((offer?.yahooRate)!)
            
            userRate = Float((offer?.userRate)!)
            //we are interested in the currency ratio only something like GBP per 1 USD so we get rid of the number of rateCurency ratio ( 1.21 GBP per 1 USD transforms into GBP per 1 USD)
            let index = offer?.rateCurrencyRatio.range(of: " ")?.lowerBound
            if let currencyRatio =  offer?.rateCurrencyRatio[index!...]{
                self.currencyRatio = String(currencyRatio)
            }
            //yahooCurency ratio is infact the number.
            let anIndex = offer?.rateCurrencyRatio.range(of: " ")?.lowerBound
            if let yahooCurrencyRatio = offer?.yahooCurrencyRatio[...anIndex!]{
                self.yahooCurrencyRatio = String(yahooCurrencyRatio)
            }
            
        }
    }

    
    func missingValue(){
            let alert = UIAlertController(title: NSLocalizedString("Missing Information", comment: "Missing Information: OfferViewController"), message: NSLocalizedString("All the text fields should have relevant information", comment: "All the text fields should have relevant information" ), preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert,animated: true)

    }
    
    func missingProfile(){
        let alert = UIAlertController(title: NSLocalizedString("Profile Missing", comment: "Profile Missing: OfferViewController"), message: NSLocalizedString("You need to create a profile, go to menu and tap on the black region", comment: "You need to create a profile, go to menu and tap on the black region" ), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert,animated: true)
    }
    
    func missingProfilePicture(){
        let alert = UIAlertController(title: NSLocalizedString("Profile Picture Missing", comment: "Profile Pictrue Missing: OfferViewController"), message: NSLocalizedString("In order to add security to MonEx, we require you to add a clear picture of your face to your profile before you can make any offers", comment: "You need to have a profile picture of your face" ), preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert,animated: true)
    }
    
    func unabeleToLocate(){
        let alert = UIAlertController(title: NSLocalizedString("Unable to locate you", comment: "Unable to locate you: OfferViewController"), message: NSLocalizedString("Browse over some offers to see if we can find your location, make sure you are connected to the internet", comment: "Browse over some offers to see if we can find your location, make sure you connected to the internet" ), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert,animated: true)

    }
    //add the done buton to the keyboad code found on stackoverflow http://stackoverflow.com/questions/28338981/how-to-add-done-button-to-numpad-in-ios-8-using-swift
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 35))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        quantitySellTextField.inputAccessoryView = doneToolbar
        quantityBuyTextField.inputAccessoryView = doneToolbar
        rateTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        quantitySellTextField.resignFirstResponder()
        quantityBuyTextField.resignFirstResponder()
        rateTextField.resignFirstResponder()
    }

    
    
}

extension OfferViewController: UITextFieldDelegate{
    
    @objc func updateOffer(){
        
        guard let yahooRate = yahooRate else{
            print("there is an error")
            return
        }
        
        //compute the QuantityBuy
        func setQuantityBuy(){
            if let sellNumber = formatterSell?.number(from: quantitySellTextField.text!) as? Float{
                switch yahooRate{
                case _ where yahooRate>=1:
                    quantityBuyTextField.text = formatterBuy?.string(from:Int(round(userRate!*sellNumber)) as NSNumber)
                case _ where yahooRate < 1:
                    quantityBuyTextField.text = formatterBuy?.string(from: Int(round(sellNumber/userRate!)) as NSNumber)
                default:
                    break
                }
            }else{
                quantityBuyTextField.text = ""
            }
        }
        
        //compute the QuantytySell
        func setQuantitySell(){
            if let buyNumber = formatterBuy?.number(from: quantityBuyTextField.text!) as? Float{
                switch yahooRate{
                case _ where yahooRate >= 1:
                    quantitySellTextField.text = formatterSell?.string(from: Int(round(buyNumber/userRate!)) as NSNumber)
                case _ where yahooRate < 1:
                    quantitySellTextField.text = formatterBuy?.string(from: Int(round(buyNumber*userRate!)) as NSNumber)
                default:
                    break
                }
            }else{
                quantitySellTextField.text = ""
            }
        }
        
        //compute user Rate
        func setUserRate(){
            if let buyNumber = formatterBuy?.number(from: quantityBuyTextField.text!) as? Float, let sellNumber = formatterSell?.number(from: quantitySellTextField.text!) as? Float{
                
                let ratio = sellNumber/buyNumber
                switch ratio{
                case _ where ratio >= 1:
                    userRate = round(ratio*100)/100
                    rateTextField.text = "\(userRate!)"
                    currencyRatioLabel.text = "\(sellCurrencyLabel.text!)" + per + "\(buyCurrencyLabel.text!)"
                case _ where ratio < 1:
                    userRate = round(1/ratio*100)/100
                    rateTextField.text = "\(userRate!)"
                    currencyRatioLabel.text = "\(buyCurrencyLabel.text!)" + per + "\(sellCurrencyLabel.text!)"
                default:
                    break
                }
            }
        }
        
        //if the sell text field is the first responder we calculate buytextfield accordingly
        if quantitySellTextField.isFirstResponder{
            if buyLastEdit{
                setUserRate()
            }else{
                setQuantityBuy()
            }
        }

        
        //if buyTextField is first responder we calculate buy text field accordingly
        if quantityBuyTextField.isFirstResponder{
            if sellLastEdit{
                setUserRate()
            }else{
                setQuantitySell()
            }
        }
        
        // we make sure that the last text field to had a meaningful edit remains the as it is and the other text field edits acording to the new rate
        if rateTextField.isFirstResponder{
            
            if let rateNumber = rateTextField.text, let rate = Float(rateNumber){
                
                userRate = rate
                if sellLastEdit{
                    setQuantityBuy()
                }else{
                    setQuantitySell()
                }
                
            }
        }
        
        //update the descrition label
        let offerDescriptionText =  String(format: NSLocalizedString("OFFER_ DESCRIPTION", comment: "I want to exchange %@cuantitySellTextField %@SellCurrencyLabel at a rate of %@rateTextField %@CurrencyRatioLabel, for a total amount of %@quantityBuyTextField %@buyCurrencyLabel: OfferViewController. English format: I want to exchange %@ %@ at a rate of %@ %@, for a total amount of %@ %@"), quantitySellTextField.text!,sellCurrencyLabel.text!, rateTextField.text!, currencyRatioLabel.text!, quantityBuyTextField.text!, buyCurrencyLabel.text!)
        
        let counterOfferDescriptionText = String(format: NSLocalizedString("COUNTER_OFFER_DESCRIPTION", comment: "I want to exchange %@cuantitySellTextField %@SellCurrencyLabel at a rate of %@rateTextField %@CurrencyRatioLabel, for a total amount of %@quantityBuyTextField %@buyCurrencyLabel: OfferViewController. English format: I want to buy %@ %@ at a rate of %@ %@, for a total amount of %@ %@") , quantitySellTextField.text!,sellCurrencyLabel.text!, rateTextField.text!, currencyRatioLabel.text!, quantityBuyTextField.text!, buyCurrencyLabel.text!)
        
        //we adjust the text depending to if is a counter offer or a regular offer
        offerDescriptionLabel.text = isCounterOffer ? counterOfferDescriptionText : offerDescriptionText
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField{
        case quantitySellTextField:
            sellLastEdit = true
            buyLastEdit = false
        case quantityBuyTextField:
            sellLastEdit = false
            buyLastEdit = true
        case rateTextField:
            sellLastEdit = false
            buyLastEdit = false
        default:
            break
        }
    }
    
    
    fileprivate func subscribeToNotification(_ notification: String, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    fileprivate func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    //The function lets the keyboard hide when return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    
    fileprivate func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }
    
    // the function returns the height of the keyboard and deterimens the displacement need it by the view to not cover the text fields
    fileprivate func keyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        if !keyboardOnScreen {
            //move the view up so we do not hide the pop up view
            view.frame.origin.y -= keyboardHeight(notification) - (view.frame.height - popUpOriginy - popUpView.frame.height) //should place it 8 points under the button
        }
        
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            view.frame.origin.y = 0
        }
    }
    
    @objc func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
        
    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
    }

    
}


extension OfferViewController: UIViewControllerTransitioningDelegate{
    
    //set the presentation controller to be the dimming Prsentation Controller, the presenting view should not be dismissed thanks to this method. The presentng controller is inquiryViewController the presented Controller is the OfferViewController
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return BounceAnimationController()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideOutAnimationController()
    }

}

extension OfferViewController: UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return (touch.view == self.view)
    }
    
}

