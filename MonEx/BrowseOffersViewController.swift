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
    
    var rootReference:FIRDatabaseReference!
    let browseCell:String = "BrowseCell"
    let nothingCellId = "NothingFoundCell"
    let userApp = AppUser.sharedInstance
    var arrayOfOffers:[Offer] = [Offer]()
    fileprivate var _refHandle: FIRDatabaseHandle!
    var storageReference: FIRStorageReference!
    let offerBidLocation = "offerBidsLocation"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //we get a reference of the storage
        configureStorage()
        
        // Register the Nib
        let cellNib = UINib(nibName: browseCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: browseCell)
       
        let nothingCellNib = UINib(nibName: nothingCellId, bundle: nil)
        tableView.register(nothingCellNib, forCellReuseIdentifier: nothingCellId)
        
        
        //set the delegate for the tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 150
        
        //get location of the user 
        userApp.getLocation(viewController: self, highAccuracy: true)
        //get arrayOfOffers 
        getArraysOfOffers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        userApp.stopLocationManager()
    }

    deinit{
        let offerBidsLocationRef = rootReference.child(offerBidLocation)
        offerBidsLocationRef.removeObserver(withHandle: _refHandle)
    }
   
    
    @IBOutlet weak var tableView: UITableView!
    
   
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func configureStorage() {
        // TODO: configure storage using your firebase storage
        storageReference = FIRStorage.storage().reference()
        
    }

    
    
    func getArraysOfOffers(){
        rootReference = FIRDatabase.database().reference()
        let offerBidsLocationRef = rootReference.child(offerBidLocation)
        
        _refHandle = offerBidsLocationRef.observe(.value, with:{ snapshot in
            
            guard let value = snapshot.value as? [String: Any] else{
                return
            }
            
            
            for key in value.keys{
                
                //the node is a dictionary of the bid
                guard let node = value[key] as? [String: Any] else{
                    print("no node was obtained")
                    return
                }
                
                guard let authorOfTheBid = node[Constants.offerBidLocation.userFirebaseId] as? String else{
                    print("no author id ")
                    return
                }
                //dictionary of the last offer in the bid is an offer
                guard let dictionary = node[Constants.offerBidLocation.lastOfferInBid] as? [String: String] else{
                    print("no dictionary")
                    return
                }
                
                guard let offer = Offer(dictionary) else{
                    print("the offer was not able to be initalized")
                    return
                }
                
                offer.authorOfTheBid = authorOfTheBid
                
                if let latitude = node[Constants.offerBidLocation.latitude] as? Double, let longitude = node[Constants.offerBidLocation.longitude] as? Double {
                    offer.latitude = latitude
                    offer.longitude = longitude
                }
                
                
                self.arrayOfOffers.append(offer)
                self.tableView.reloadData()
            }
        })
        
    }
}




extension BrowseOffersViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return arrayOfOffers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: browseCell, for: indexPath) as! BrowseCell
        cell.storageReference = storageReference
        let offer = arrayOfOffers[indexPath.row]
        cell.configure(for: offer)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let offer = arrayOfOffers[indexPath.row]
        let acceptOfferViewController = storyboard?.instantiateViewController(withIdentifier: "acceptOfferViewController") as! AcceptOfferViewController
        acceptOfferViewController.offer = offer
        acceptOfferViewController.authorOfTheBid = offer.authorOfTheBid
        let navigationController = self.navigationController
        navigationController?.pushViewController(acceptOfferViewController, animated: true)
        
        
    }
}
