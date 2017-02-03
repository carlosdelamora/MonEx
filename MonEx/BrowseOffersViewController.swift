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
            
            for children in snapshot.children{
                print(children)
            }
            
        })
        
    }
}




extension BrowseOffersViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BrowseCell", for: indexPath) as! BrowseCell
        return cell
    }
}
