//
//  AcceptOfferViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/6/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class AcceptOfferViewController: UIViewController {

    
    @IBOutlet weak var profileView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var sellQuantityTextField: UITextField!
    
    @IBOutlet weak var sellCurrencyLabel: UILabel!
    @IBOutlet weak var buyQuantityTextField: UITextField!
    
    @IBOutlet weak var buyCurrencyLabel: UILabel!
    
    
    @IBOutlet weak var sellLabel: UILabel!
    
    @IBOutlet weak var buyLabel: UILabel!
    
    @IBOutlet weak var offerAcceptanceDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

  

}
