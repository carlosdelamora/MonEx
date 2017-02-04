//
//  BrowseOffersViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/31/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Firebase

class BrowseOffersViewController: UIViewController {
    
    var rootReference:FIRDatabaseReference!
    let browseCell:String = "BrowseCell"
    let userApp = AppUser.sharedInstance
    var arrayOfOffers:[Offer] = [Offer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register the Nib
        let cellNib = UINib(nibName: "BrowseCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "BrowseCell")
        
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

    @IBOutlet weak var tableView: UITableView!
    
   
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func getArraysOfOffers(){
        rootReference = FIRDatabase.database().reference()
        let offerBidsLocationRef = rootReference.child("offerBidsLocation")
        
        offerBidsLocationRef.observe(.value, with:{ snapshot in
            
            guard let value = snapshot.value as? [String: Any] else{
                return
            }
            print(value)
            for key in value.keys{
                guard let node = value[key] as? [String: Any] else{
                    print("no node was obtained")
                    return
                }
                guard let dictionary = node["lastOfferInBid"] as? [String: String] else{
                    print("no dictionary")
                    return
                }
                
                guard let offer = Offer(dictionary) else{
                    print("the offer was not able to be initalized")
                    return
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BrowseCell", for: indexPath) as! BrowseCell
        let offer = arrayOfOffers[indexPath.row]
        DispatchQueue.main.async {
            cell.leftImageFlag.image = UIImage(named: offer.sellCurrencyCode + "small")
            cell.rightImageFlag.image = UIImage(named: offer.buyCurrencyCode + "small")
        }
        
        return cell
    }
}
