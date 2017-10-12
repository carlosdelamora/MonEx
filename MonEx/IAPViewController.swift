//
//  IAPViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 10/11/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import StoreKit
import Firebase

class IAPViewController: UIViewController {

    var _referenceHandle: FIRDatabaseHandle?
    let appUser = AppUser.sharedInstance
    let rootReference = FIRDatabase.database().reference()
    var credits: Int?{
        didSet{
            let labelText = String(format: NSLocalizedString("Credits: %@", comment: "Credits: %@"), "\(credits ?? 0)")
            creditLabel.text = labelText
        }
    }
    
    @IBOutlet weak var creditLabel: UILabel!
    @IBOutlet weak var buyThreeCreditsButton: UIButton!
    
    //let iAPHelper = IAPHelper(prodId: Set(["com.carlosDelaMora.MonEx.credits"]))
    let threeCreditProductId = "com.carlosDelaMora.MonEx.credits"
    var iAPHelper: IAPHelper?{
        didSet{
            updateIAPHelper()
        }
    }
    
    var buyThreeCreditsProduct: SKProduct?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iAPHelper = IAPHelper(prodId: Set(["com.carlosDelaMora.MonEx.credits"]))
        view.backgroundColor = Constants.color.paternColor
        let text = NSLocalizedString("Buy 3 credits", comment: "Buy 3 credits")
        if let font = UIFont(name: "Helvetica-Bold", size: 21){
            let attributedText = NSAttributedString(string: text, attributes: [.font:font, .foregroundColor: UIColor.black])
            buyThreeCreditsButton.setAttributedTitle(attributedText, for: .normal)
        }
        buyThreeCreditsButton.layer.cornerRadius = 5
        buyThreeCreditsButton.clipsToBounds = true
        
        //reference handle for the credits
        _referenceHandle = rootReference.child("Users/\(appUser.firebaseId)/credits").observe(.value, with:{ snapshot in
            guard let credits = snapshot.value as? Int else{
                return
            }
            self.credits = credits
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
    }
    
    deinit {
        if let _referenceHandle = _referenceHandle{
            rootReference.child("Users/\(appUser.firebaseId)/credits").removeObserver(withHandle: _referenceHandle)
        }
    }
    
    @IBAction func doneButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func buyThreeCreditsButton(_ sender: Any) {
        guard let buyThreeCreditsProduct = buyThreeCreditsProduct else { return }
        iAPHelper?.buyAProduct(product: buyThreeCreditsProduct)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    
    private func updateIAPHelper(){
        guard let iAPhelper = iAPHelper else { return }
        
        //we request the products and filter to obtain the one that corresponds to the three credit product
        iAPhelper.requestProducts { (products) in
            self.buyThreeCreditsProduct = products?.filter({$0.productIdentifier == self.threeCreditProductId}).first
        }
    }

   
}
