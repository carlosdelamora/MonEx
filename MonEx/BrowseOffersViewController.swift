//
//  BrowseOffersViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/31/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorageUI

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

    }
    
    
    @IBAction func done(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func getTheOffers(){
        switch currentTable{
        case .browseOffers:
            path = Constants.offerBidLocation.offerBidsLocation
            _refHandle = getOffers.getArraysOfOffers(path: path, completion:{
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.doneButton.isEnabled = true
                }
            })
        case .myBids:
            path = "Users/\(appUser.firebaseId)/Bid"
            _refHandle = getOffers.getMyBidsArray(path: "Users/\(appUser.firebaseId)/Bid", completion:{
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.doneButton.isEnabled = true
                }
            })
        case .myOffersInBid:
            print("thngs to do")
        }

    }
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        storageReference = FIRStorage.storage().reference()
    }
}




extension BrowseOffersViewController: UITableViewDataSource, UITableViewDelegate{
    
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        switch getOffers.currentStatus{
        case .notsearchedYet:
            return 0
        case .loading:
            doneButton.isEnabled = false
            return 1
        case .nothingFound:
            return 1
        case .results(let list):
            return list.count
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
        case .results(let list):
            let cell = tableView.dequeueReusableCell(withIdentifier: browseCell, for: indexPath) as! BrowseCell
            //we need a reference to the storage to download the pictures from firebase of core data
            cell.storageReference = storageReference
            let offer = list[indexPath.row]
            cell.configure(for: offer)
            if case currentTable = tableToPresent.myBids{
                cell.isUserInteractionEnabled = false
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
            //whiteRoundedView.layer.shadowOffset = CGSize(width: 1, height: 1)
            //whiteRoundedView.layer.shadowOpacity = 0.2
            
            cell.contentView.addSubview(whiteRoundedView)
            cell.contentView.sendSubview(toBack: whiteRoundedView)
            
            
            return cell
        }
    }
    

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .results(let list) = getOffers.currentStatus{
            
            let offer = list[indexPath.row]
            appUser.getBidStatus(bidId: offer.bidId!, completion: { status in
                
                
                switch status.rawValue{
                case Constants.appUserBidStatus.lessThanFive, Constants.appUserBidStatus.approved:
                    //less than five minutes or if is active it should procceed to acceptViewController
                    self.completion(offer: offer)
                default:
                    //in this case the we show the transaction has expired and update the bid to non active
                    self.showExpiredAlert()
                }
                
            })
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
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
            case Constants.offerStatus.active, Constants.offerStatus.approved:
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
                            
                            let navigationController = self.navigationController
                            navigationController?.pushViewController(acceptOfferViewController, animated: true)
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
        let alert = UIAlertController(title: NSLocalizedString("The request has expired", comment: "The request has expired"), message: "The request that have not been approved expire after 5 min", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    
}
