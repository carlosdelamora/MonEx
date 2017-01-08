//
//  OfferViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class OfferViewController: UIViewController {
    

    var sellCurrency: String?
    var buyCurrency: String?
    var currencyRatio: String?
    var quantitySell: String?
    var quantityBuy: String?
    var rate: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sellCurrencyLabel.text = sellCurrency
        buyCurrencyLabel.text = buyCurrency
        currencyRatioLabel.text = currencyRatio
        quantitySellTextField.text = quantitySell
        quantityBuyTextField.text = quantityBuy
        rateTextField.text = rate
        // Do any additional setup after loading the view.
        offerDescriptionLabel.text = NSLocalizedString(String(format:"I want to exchange %@ %@ at a rate of %@ %@, for a total amount of %@ %@",quantitySell!,sellCurrency!, rate!, currencyRatio!, quantityBuy!, buyCurrency!), comment: "")
        
        popUpView.layer.cornerRadius = 10
    }

 
    @IBAction func makeOffer(_ sender: Any) {
        //post it to the data base
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


