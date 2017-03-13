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
        
        getTheOffers()
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
                }
            })
        case .myBids:
            path = "Users/\(appUser.firebaseId)/Bid"
            _refHandle = getOffers.getMyBidsArray(path: "Users/\(appUser.firebaseId)/Bid", completion:{
                DispatchQueue.main.async {
                    self.tableView.reloadData()
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
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .results(let list) = getOffers.currentStatus{
            
            let offer = list[indexPath.row]
            let acceptOfferViewController = storyboard?.instantiateViewController(withIdentifier: "acceptOfferViewController") as! AcceptOfferViewController
            //we make the offer the default offer in acceptedOfferViewController and only changeit to the transpose if need it. 
            acceptOfferViewController.offer = offer
            switch currentTable{
            case .browseOffers:
                
                acceptOfferViewController.currentStatus = .acceptOffer
                let navigationController = self.navigationController
                navigationController?.pushViewController(acceptOfferViewController, animated: true)
            case .myBids:
            
                getOffers.getTransposeAcceptedOffer(path: "transposeOfacceptedOffer/\(offer.firebaseId)/\(offer.bidId!)"){
    
                    //we check if the user is the creator of the bid
                    if offer.firebaseId == self.appUser.firebaseId{
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
                }
            case .myOffersInBid:
                print("get the counteroffres")
            }
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}
