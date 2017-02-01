//
//  BrowseOffersViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/31/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class BrowseOffersViewController: UIViewController {

    let browseCell:String = "BrowseCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register the Nib
        let cellNib = UINib(nibName: browseCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: browseCell)
        //set the delegate for the tableView
        tableView.delegate = self
        tableView.dataSource = self 
    }

    @IBOutlet weak var tableView: UITableView!
    
}

extension BrowseOffersViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BrowseCell", for: indexPath) as! BrowseOffersViewCell
        return cell
    }
}
