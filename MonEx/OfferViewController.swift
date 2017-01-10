//
//  OfferViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class OfferViewController: UIViewController {
    
    var keyboardOnScreen = false
    var popUpOriginy: CGFloat = 0
    var sellCurrency: String?
    var buyCurrency: String?
    var currencyRatio: String?
    var quantitySell: String?
    var quantityBuy: String?
    var rate: String?
    var yahooRate: Float? 
    var userRate: Float?
    var sellLastEdit = true
    
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
        
        
        //set the attrubutes coming form the Inquiry View Controller
        sellCurrencyLabel.text = sellCurrency
        buyCurrencyLabel.text = buyCurrency
        currencyRatioLabel.text = currencyRatio
        if let quantity = quantitySell, let sellNumber = Float(quantity){
            quantitySellTextField.text = String(format: "%d", Int(round(sellNumber)))
        }else{
            quantitySellTextField.text = ""
        }
        
        if let quantity = quantityBuy, let buyNumber = Float(quantity){
            quantityBuyTextField.text = String(format: "%d", Int(round(buyNumber)))
        }else{
            quantityBuyTextField.text = ""
        }
        
        rateTextField.text = rate
        updateOffer()
        
        
        //placeholders 
        quantitySellTextField.placeholder = NSLocalizedString("Qty", comment: "Qty: place holder in the offerViewController")
        quantityBuyTextField.placeholder = NSLocalizedString("Qty", comment: "Qty: place holder in the offerViewController")
        
        //Do some styling for the popUpView
        popUpView.layer.cornerRadius = 10
        //make the background clear 
        view.backgroundColor = UIColor.clear
        
        //Add a gesture recognizer with an acction so that the Offer View Controller dismisses 
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeOffer))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        //set the delegats for text fields 
        quantitySellTextField.delegate = self
        quantityBuyTextField.delegate = self
        rateTextField.delegate = self
        
        //set the keyboards 
        quantitySellTextField.keyboardType = .numberPad
        quantityBuyTextField.keyboardType = .numberPad
        rateTextField.keyboardType = .decimalPad
        addDoneButtonOnKeyboard()
        
        
        // subscribe to notifications to update the Description label 
        subscribeToNotification(NSNotification.Name.UITextFieldTextDidChange.rawValue, selector: #selector(updateOffer))
        //subscibe to notifications in order to move the view up or down
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: #selector(keyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: #selector(keyboardDidHide))

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        popUpOriginy = popUpView.frame.origin.y
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
 
    @IBAction func makeOffer(_ sender: Any) {
        //post it to the data base
    }
    
    
    @IBAction func closeOffer(_ sender: Any) {
       dismiss(animated: true, completion: nil)
    }
    
    //add the done buton to the keyboad code found on stackoverflow http://stackoverflow.com/questions/28338981/how-to-add-done-button-to-numpad-in-ios-8-using-swift
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 35))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        quantitySellTextField.inputAccessoryView = doneToolbar
        quantityBuyTextField.inputAccessoryView = doneToolbar
        rateTextField.inputAccessoryView = doneToolbar
        
    }
    
    func doneButtonAction() {
        quantitySellTextField.resignFirstResponder()
        quantityBuyTextField.resignFirstResponder()
        rateTextField.resignFirstResponder()
    }

    
}

extension OfferViewController: UITextFieldDelegate{
    
    func updateOffer(){
        
        guard let yahooRate = yahooRate else{
            print("there is an error")
            return
        }
        
       
        
        userRate = yahooRate
        
        if quantitySellTextField.isFirstResponder{
            if let quantity = quantitySellTextField.text, let sellNumber = Float(quantity){
                sellLastEdit = true
                
                quantityBuyTextField.text = String(format: "%d", Int(round(userRate!*sellNumber)))
            }else{
                quantityBuyTextField.text = ""
            }
        }
        
        if quantityBuyTextField.isFirstResponder{
            if let quantity = quantityBuyTextField.text, let buyNumber = Float(quantity){
                sellLastEdit = false
                quantitySellTextField.text = String(format: "%d", Int(round(buyNumber/userRate!)))
            }else{
                quantityBuyTextField.text = ""
            }
        }
        
        guard let sellNumber = Float(quantitySellTextField.text!) else{
            return
        }
        
        guard let buyNumber = Float(quantityBuyTextField.text!) else{
            return
        }
        
        // we make sure that the last text field to had a meaningful edit remains the as it is and the other text field edits acording to the new rate
        if rateTextField.isFirstResponder{
            if let rateNumber = rateTextField.text, let rate = Float(rateNumber){
                userRate = rate
                
                
                if sellLastEdit{
                    
                    switch yahooRate{
                    case _ where yahooRate>=1:
                        quantityBuyTextField.text = String(format: "%d", Int(round(userRate!*sellNumber)))
                    case _ where yahooRate < 1:
                        quantityBuyTextField.text = String(format: "%d", Int(round(userRate!*buyNumber)))
                    default:
                        break
                    }
                    
                    
                }
                
            }
            
        }
        
        //update the descrition label
        offerDescriptionLabel.text = NSLocalizedString(String(format:"I want to exchange %@ %@ at a rate of %@ %@, for a total amount of %@ %@", quantitySellTextField.text!,sellCurrencyLabel.text!, rateTextField.text!, currencyRatioLabel.text!, quantityBuyTextField.text!, buyCurrencyLabel.text!), comment: "")
        
        
      
    }
    
    fileprivate func subscribeToNotification(_ notification: String, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    fileprivate func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    //The function lets the keyboard hide when return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    
    fileprivate func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }
    
    // the function returns the height of the keyboard and deterimens the displacement need it by the view to not cover the text fields
    fileprivate func keyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    
    func keyboardWillShow(_ notification: Notification) {
        
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification) - (view.frame.height - popUpOriginy - popUpView.frame.height) //should place it 8 points under the button
        }
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            view.frame.origin.y = 0
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
        
    }
    
    func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
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

extension OfferViewController: UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return (touch.view == self.view)
    }
    
}

