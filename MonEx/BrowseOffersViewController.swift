//
//  BrowseOffersViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/31/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Firebase
//import FirebaseStorageUI

class BrowseOffersViewController: UIViewController {
    
    let rootReference = FIRDatabase.database().reference()
    let browseCell:String = "BrowseCell"
    let nothingCellId = "NothingFoundCell"
    let loadingCellId = "loadingCell"
    let appUser = AppUser.sharedInstance
    var arrayOfOffers:[Offer] = [Offer]()
    fileprivate var _refHandle: FIRDatabaseHandle!
    var storageReference: FIRStorageReference!
    let getOffers = GetOffers()
    var path: String = Constants.offerBidLocation.offerBidsLocation
    var currentTable: tableToPresent = .browseOffers
    var activity = UIActivityIndicatorView()
    
    enum tableToPresent{
        case browseOffers
        case myBids
        case myOffersInBid
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //we get a reference of the storage
        configureStorage()
        
        // Register the Nib
        let cellNib = UINib(nibName: browseCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: browseCell)
        
        let nothingCellNib = UINib(nibName: nothingCellId, bundle: nil)
        tableView.register(nothingCellNib, forCellReuseIdentifier: nothingCellId)
        
        //let loadingCellNib = UINib(nibName: loadingCellId, bundle: nil)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: loadingCellId)
        
        
        //set the delegate for the tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 150
        
        //get location of the user
        appUser.getLocation(viewController: self, highAccuracy: true)
        
        //set the color of the navigation bar
        let navigationController = self.navigationController!
        let navigationBar = navigationController.navigationBar
        //navigationController.preferredStatusBarStyle = .lightContent
        navigationBar.barTintColor = Constants.color.greyLogoColor
        
        //set the color of the tableView
        tableView.backgroundColor = Constants.color.greyLogoColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //appUser.stopLocationManager()
        let reference = rootReference.child(path)
        reference.removeObserver(withHandle: _refHandle)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //get the most current offers
        getTheOffers()
        //set the array of offers
        

    }
    
    
    @IBAction func done(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func getTheOffers(){
        addActivityIndicator()
        switch currentTable{
        case .browseOffers:
            path = Constants.offerBidLocation.offerBidsLocation
            _refHandle = getOffers.getArraysOfOffers(path: path, completion:{
                DispatchQueue.main.async {
                    self.setArrayOfOffers()
                    self.tableView.reloadData()
                    self.doneButton.isEnabled = true
                    self.stopAcivityIndicator()
                }
            })
        case .myBids:
            path = "Users/\(appUser.firebaseId)/Bid"
            _refHandle = getOffers.getMyBidsArray(path: "Users/\(appUser.firebaseId)/Bid", completion:{
                DispatchQueue.main.async {
                    self.setArrayOfOffers()
                    self.tableView.reloadData()
                    self.doneButton.isEnabled = true
                    self.stopAcivityIndicator()
                }
            })
        case .myOffersInBid:
            print("tihngs to do")
        }

    }
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        storageReference = FIRStorage.storage().reference()
    }
    
    func setArrayOfOffers(){
        switch getOffers.currentStatus{
        case .notsearchedYet, .loading, .nothingFound:
             break
        case .results(let list):
            arrayOfOffers = list
        }
    }
    
    func addActivityIndicator(){
        DispatchQueue.main.async {
            self.activity.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.activity)
            self.view.centerXAnchor.constraint(equalTo: self.activity.centerXAnchor).isActive = true
            self.view.centerYAnchor.constraint(equalTo: self.activity.centerYAnchor).isActive = true
            self.activity.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.activity.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.activity.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.activity.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            //self.activity.widthAnchor.constraint(equalToConstant: 100).isActive = true
            //self.activity.activityIndicatorViewStyle =
            self.activity.activityIndicatorViewStyle = .whiteLarge
            self.activity.backgroundColor = UIColor(white: 0, alpha: 0.25)
            //self.activity.sizeThatFits(CGSize(width: 80, height: 80))
            self.activity.startAnimating()
        }
    }
    
    func stopAcivityIndicator(){
        activity.stopAnimating()
        activity.removeFromSuperview()
        activity.stopAnimating()
    }

}




extension BrowseOffersViewController: UITableViewDataSource, UITableViewDelegate{
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete{
            if case .results( _) = getOffers.currentStatus{
                let offer = arrayOfOffers[indexPath.row]
                if offer.offerStatus.rawValue != Constants.offerStatus.nonActive{
                    canNotDelete()
                    return 
                }
                
                deleteAllTheInfo(bidId: offer.bidId!)
                arrayOfOffers.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?{
        if currentTable == .myBids{
            return nil
        }
        return [UITableViewRowAction]()
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        switch getOffers.currentStatus{
        case .notsearchedYet:
            return 0
        case .loading:
            doneButton.isEnabled = false
            return 1
        case .nothingFound:
            return 1
        case .results( _):
            return arrayOfOffers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch getOffers.currentStatus{
        case .notsearchedYet, .loading:
            let cell = tableView.dequeueReusableCell(withIdentifier: loadingCellId, for: indexPath) as! LoadingCell
            let spiner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spiner.startAnimating()
            return cell
        case .nothingFound:
            let cell = tableView.dequeueReusableCell(withIdentifier: nothingCellId, for: indexPath) as!
            NothingFoundCell
            return cell
        case .results(_):
            let cell = tableView.dequeueReusableCell(withIdentifier: browseCell, for: indexPath) as! BrowseCell
            //we need a reference to the storage to download the pictures from firebase of core data
            cell.storageReference = storageReference
            let offer = arrayOfOffers[indexPath.row]
            cell.configure(for: offer)
            if case currentTable = tableToPresent.myBids{
                //cell.isUserInteractionEnabled = false
                cell.selectionStyle = .none
            }
            
            cell.contentView.backgroundColor = UIColor.clear
            
            let separator:CGFloat = 3
            let whiteRoundedView : UIView = UIView(frame: CGRect(x: separator, y: separator, width: self.view.frame.size.width - 2*separator, height: 150 - 2*separator))
            
            whiteRoundedView.layer.backgroundColor = Constants.color.greyLogoColor.cgColor
            whiteRoundedView.layer.borderColor = Constants.color.greyLogoColor.cgColor
            whiteRoundedView.layer.borderWidth = 1
            whiteRoundedView.layer.masksToBounds = false
            whiteRoundedView.layer.cornerRadius = 5.0
            cell.contentView.addSubview(whiteRoundedView)
            cell.contentView.sendSubview(toBack: whiteRoundedView)
            
            
            return cell
        }
    }
    

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .results(let list) = getOffers.currentStatus{
            
            let offer = list[indexPath.row]
            if case currentTable = tableToPresent.myBids{
                if offer.offerStatus.rawValue == Constants.offerStatus.nonActive{
                    self.completion(offer: offer)
                    return
                }
                
                self.appUser.getBidStatus(bidId: offer.bidId!, completion: { status in
                    switch status.rawValue{
                    
                        //the case noBid is also included in case that the bidInfo was erased, this could have happened if the bid has expired or possibly if the bid was rejected and did not get the notification. 
                    case Constants.appUserBidStatus.moreThanFiveUserLastToWrite, Constants.appUserBidStatus.moreThanFiveOtherLastToWrite, Constants.appUserBidStatus.noBid:
                        //in this case the we show the transaction has expired and update the bid to non active
                        DispatchQueue.main.async {
                            self.showExpiredAlert()
                        }
                        let pathToUpdate = "/Users/\(self.appUser.firebaseId)/Bid/\(offer.bidId!)/offer/\(Constants.offer.offerStatus)"
                        let lastOfferInBidStatusPath = "offerBidsLocation/\(offer.bidId!)/lastOfferInBid/\(Constants.offer.offerStatus)"
                        self.rootReference.updateChildValues( [pathToUpdate: Constants.offerStatus.nonActive])
                        
                        self.rootReference.updateChildValues([lastOfferInBidStatusPath: Constants.offerStatus.nonActive])
                        self.deleteInfo(bidId: offer.bidId!)
                    
                    case Constants.appUserBidStatus.approved,Constants.appUserBidStatus.active, Constants.appUserBidStatus.complete:
                        if offer.offerStatus.rawValue != status.rawValue{
                            offer.offerStatus = Offer.status(rawValue: status.rawValue)!
                            let pathToUpdate = "/Users/\(self.appUser.firebaseId)/Bid/\(offer.bidId!)/offer/\(Constants.offer.offerStatus)"
                             self.rootReference.updateChildValues( [pathToUpdate: status.rawValue])
                        }
                        self.completion(offer: offer)
                    default:
                        //less than five minutes or if is active or completed it should procceed to acceptViewController
                        
                        self.completion(offer: offer)
                    }
                    
                })
            }else{
                self.completion(offer: offer)
            }
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    //we use this function to erase the data when there is no response.
    func deleteInfo(bidId:String){
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
            
            
            //if the author of the bid is not the user the we erase the path to my bids otherwise is already updated
            if authorOfTheBid != self.appUser.firebaseId {
                let pathToMyBids = "/Users/\(self.appUser.firebaseId)/Bid/\(bidId)" //set to null
                self.rootReference.updateChildValues([pathToMyBids: NSNull()])
            }
            
            let pathForCounterOffer = "/counterOffer/\(authorOfTheBid)/\(bidId)"//set to null
            //set to Null
            let pathForCounterOfferOther = "/counterOffer/\(otherUser)/\(bidId)"//set to null
            self.rootReference.updateChildValues([pathForCounterOffer: NSNull()])
            self.rootReference.updateChildValues([pathForCounterOfferOther:NSNull()])
            
        })
    }

    
    func completion(offer: Offer){
        
        let acceptOfferViewController = storyboard?.instantiateViewController(withIdentifier: "acceptOfferViewController") as! AcceptOfferViewController
        //we make the offer the default offer in acceptedOfferViewController and only changeit to the transpose if need it.
        acceptOfferViewController.offer = offer

        switch currentTable{
        case .browseOffers:
            
            acceptOfferViewController.currentStatus = .acceptOffer
            let navigationController = self.navigationController
            navigationController?.pushViewController(acceptOfferViewController, animated: true)
        case .myBids:
            
            
            
            switch offer.offerStatus.rawValue{
            case Constants.offerStatus.nonActive:
                //we should not be able to select a non active offer
                print("nonActive")
            case Constants.offerStatus.active, Constants.offerStatus.approved, Constants.offerStatus.halfComplete:
                // if the offer is active we need to check if he is the user is the creator of the offer and acct accordingly. If the current user is the creator he needs to confirm the activation made by another client, in this case there is a transpose offer. Otherwise if he is not the creator he is wating for confirmation by the creator. In that case there is not transpose offer.
                
                //we check if the user is the creator of the bid
                if offer.firebaseId == self.appUser.firebaseId{
                    getOffers.getTransposeAcceptedOffer(path: "transposeOfacceptedOffer/\(offer.firebaseId)/\(offer.bidId!)"){
                        
                        // tere should be a transpose offer if the user is the creator of the bid
                        if let transposeOffer = self.getOffers.transposeOffer{
                            transposeOffer.bidId = offer.bidId!
                            transposeOffer.offerStatus = offer.offerStatus
                            acceptOfferViewController.offer = transposeOffer
                            switch transposeOffer.offerStatus.rawValue{
                            case Constants.offerStatus.active:
                                //we are here if the user is the creator and the offer has been accepted, then we need action for confirmation
                                acceptOfferViewController.currentStatus = .offerAcceptedNeedConfirmation
                            case Constants.offerStatus.approved:
                                acceptOfferViewController.currentStatus = .offerConfirmed
                            default:
                                print("default")
                            }
                            
                           
                            DispatchQueue.main.async {
                                self.navigationController?.pushViewController(acceptOfferViewController, animated: true)
                            }
                            
                        }
                    }
                }else{
                    
                    //if he is not the creator of the bid we present different status con the accept view Controller
                    switch offer.offerStatus.rawValue{
                    case Constants.offerStatus.active:
                        //we are here if the user is not the creator and the offer has been accepted, then we need to wait for confirmationn and is not our action
                        acceptOfferViewController.currentStatus = .waitingForConfirmation
                    case Constants.offerStatus.approved:
                        acceptOfferViewController.currentStatus = .offerConfirmed
                    default:
                        print("default")
                    }
                    
                    let navigationController = self.navigationController
                    navigationController?.pushViewController(acceptOfferViewController, animated: true)
                }
                
                print("active")
            case Constants.offerStatus.counterOffer, Constants.offerStatus.counterOfferApproved:
                //if is a counteroffer
                getOffers.getCounterOffer(path: "counterOffer/\(appUser.firebaseId)/\(offer.bidId!)"){
                    
                    
                    if let counteroffer = self.getOffers.counteroffer{
                        
                        if counteroffer.firebaseId == self.appUser.firebaseId{
                            
                            
                            counteroffer.offerStatus = offer.offerStatus
                            switch counteroffer.offerStatus.rawValue{
                            case Constants.offerStatus.counterOffer:
                                //The user is the creator of the counteroffer(countercounteroffer in fact) thus should be waiting for confirmation
                                acceptOfferViewController.currentStatus = .waitingForConfirmation
                                let navigationController = self.navigationController
                                navigationController?.pushViewController(acceptOfferViewController, animated: true)
                            case Constants.offerStatus.counterOfferApproved:
                                //The user is the creator of the counteroffer(countercounteroffer in fact) the counteroffer has been approved
                                acceptOfferViewController.currentStatus = .offerConfirmed
                                let navigationController = self.navigationController
                                navigationController?.pushViewController(acceptOfferViewController, animated: true)
                            default:
                                print("how did we get here?")
                            }
                            
                            
                        }else{
                            counteroffer.bidId = offer.bidId!
                            counteroffer.offerStatus = offer.offerStatus
                            acceptOfferViewController.offer = counteroffer
                            switch counteroffer.offerStatus.rawValue{
                            case Constants.offerStatus.counterOffer:
                                //we are here if the user is not the creator of the counteroffer, then we need action for confirmation, rejection or counteroffer
                                acceptOfferViewController.currentStatus = .counterOfferConfirmation
                            case Constants.offerStatus.counterOfferApproved:
                                acceptOfferViewController.currentStatus = .offerConfirmed
                            default:
                                print("default")
                            }
                            
                            let navigationController = self.navigationController
                            navigationController?.pushViewController(acceptOfferViewController, animated: true)
                            
                        }
                    }else{
                        
                        //The user is the creator of the counteroffer, and has not received any counteroffers. Then there is no need to read offres from the counteroffers the user reads from its bids
                        switch offer.offerStatus.rawValue{
                        case Constants.offerStatus.counterOffer:
                            //The user is the creator of the counteroffer(countercounteroffer in fact) thus should be waiting for confirmation
                            acceptOfferViewController.currentStatus = .waitingForConfirmation
                            let navigationController = self.navigationController
                            navigationController?.pushViewController(acceptOfferViewController, animated: true)
                        case Constants.offerStatus.counterOfferApproved:
                            //The user is the creator of the counteroffer(countercounteroffer in fact) the counteroffer has been approved
                            acceptOfferViewController.currentStatus = .offerConfirmed
                            let navigationController = self.navigationController
                            navigationController?.pushViewController(acceptOfferViewController, animated: true)
                        default:
                            print("how did we get here?")
                        }
                    }
                }
                
                print("counterOffer")
            case Constants.offerStatus.counterOfferApproved:
                // in the case it has been approved
                
                print("approved")
            case Constants.offerStatus.complete:
                print("complete")
            default:
                print("I do not know why is complaining if I do not have this default")
            }
            
        case .myOffersInBid:
            print("get the counteroffres")
        }
    }
    
    
    
    func showExpiredAlert(){
        let alert = UIAlertController(title: NSLocalizedString("The request has expired", comment: "The request has expired"), message: NSLocalizedString("The requests that have not been approved expire after 5 min", comment: "The request that have not been approved expire after 5 min") , preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler:{ (alert) in
            self.getTheOffers()
        })
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func canNotDelete(){
        let alert = UIAlertController(title: NSLocalizedString("Can not delete", comment: "Can not delete"), message: NSLocalizedString("To Delete this offer it needs first to be rejected or finished", comment: "To Delete this offer it needs first to be rejected or finished"), preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler:{ (alert) in
            self.getTheOffers()
        })
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    
    //we delete the bid and all the info pretending to it
    func deleteAllTheInfo(bidId: String){
        
        var bidsDictionary = appUser.bidIds
        let index = bidsDictionary.index(of: bidId)
        if let indexOfBid = index{
            bidsDictionary.remove(at: indexOfBid)
            appUser.bidIds = bidsDictionary
        }
        
        
        let pathForBidStatus = "/bidIdStatus/\(bidId)" // set to Null
        let pathForBidLocation = "/offerBidsLocation/\(bidId)" // set to Null
        let pathToMyBids = "/Users/\(self.appUser.firebaseId)/Bid/\(bidId)" // set to null
        let pathBid = "/\(bidId)"
        rootReference.updateChildValues([pathForBidStatus: NSNull(), pathForBidLocation: NSNull(), pathToMyBids: NSNull(), pathBid: NSNull()])
        
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
            
            self.appUser.getOtherOffer(bidId: bidId){ otherOffer in
                
                let pathForCounterOffer = "/counterOffer/\(authorOfTheBid)/\(bidId)"//set to null
                //set to Null
                let pathForCounterOfferOther = "/counterOffer/\(otherUser)/\(bidId)"
                
                if let otherOffer = otherOffer{
                    let pathForTranspose = "/transposeOfacceptedOffer/\(otherOffer.firebaseIdOther!)/\(bidId)"// set to Null
                    self.rootReference.updateChildValues([pathForBidStatus: NSNull(), pathForBidLocation: NSNull(), pathForTranspose: NSNull(), pathToMyBids: NSNull()])
                    self.rootReference.setValue([pathForCounterOffer:NSNull()])
                    self.rootReference.setValue([pathForCounterOfferOther: NSNull()])
                }else{
                    self.rootReference.setValue([pathForCounterOffer:NSNull()])
                    self.rootReference.setValue([pathForCounterOfferOther: NSNull()])
                }
                
            }
            
        })
    }

}
