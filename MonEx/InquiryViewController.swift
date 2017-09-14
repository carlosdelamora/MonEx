//
//  InquiryViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/3/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Firebase
//import GoogleSignIn
import CoreData
import FBSDKLoginKit
import UserNotifications


class InquiryViewController: UIViewController {
    
    
    var keyboardOnScreen = false
    var offerViewOnScreen = false
    var yahooClient = YahooClient()
    var user: FIRUser?
    var context: NSManagedObjectContext? = nil
    let appUser = AppUser.sharedInstance
    var sellLastEdit:Bool = false
    var buyLastEdit:Bool = false
    var activity = UIActivityIndicatorView()
    
    
    override var shouldAutorotate: Bool{
        return false
    }
   
    
    //We use this array to populate the picker View
    let arrayOfCurrencies = [Constants.currency.ARS, Constants.currency.AUD,Constants.currency.BRL, Constants.currency.CAD,Constants.currency.COP,Constants.currency.EUR, Constants.currency.GBP, Constants.currency.MXN,Constants.currency.USD]
    
    //MARK: -Outles
    
    @IBOutlet weak var sellLabel: UILabel!
    @IBOutlet weak var buyLabel: UILabel!
    
    
    
    @IBOutlet weak var myBidsButton: UIBarButtonItem!
    @IBOutlet weak var leftFlag: UIImageView!
    @IBOutlet weak var rightFlag: UIImageView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var leftTextField: UITextField!
    @IBOutlet weak var rightTextField: UITextField!
    
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    
    @IBOutlet weak var makeOfferItem: UIBarButtonItem!
    @IBOutlet weak var browseOfferItem: UIBarButtonItem!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var toolBar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        //set the background for the view
        view.backgroundColor = Constants.color.paternColor
        
        //set the background for the navigationBar
        navigationBar.barTintColor = Constants.color.greyLogoColor
        toolBar.barTintColor = Constants.color.greyLogoColor
        
        
        //set the labels style and text 
        sellLabel.text = NSLocalizedString("SELL", comment: "SELL: top label inquiryController")
        buyLabel.text = NSLocalizedString("BUY", comment: "BUY: top label inquiryController")
        sellLabel.font = UIFont(name: ".SFUIDisplay-Bold" , size: 25)
        buyLabel.font = UIFont(name: ".SFUIDisplay-Bold" , size: 25)
        sellLabel.backgroundColor = Constants.color.greenLogoColor
        buyLabel.backgroundColor = Constants.color.greenLogoColor
        sellLabel.textColor = Constants.color.greyLogoColor
        buyLabel.textColor = Constants.color.greyLogoColor
        leftLabel.textColor = .white
        rightLabel.textColor = .white
        
        
        //set the context for core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        appUser.context = context 
        
        //Picker Set up
        pickerView.delegate = self
        pickerView.dataSource = self
        
        
        //textField Delegate set up
        leftTextField.delegate = self
        rightTextField.delegate = self
        leftTextField.keyboardType = UIKeyboardType.numberPad
        rightTextField.keyboardType = UIKeyboardType.numberPad
        leftTextField.text = ""
        rightTextField.text = ""
                
        //add the Done to the keyboard
        addDoneButtonOnKeyboard()
        
        //set round edges for the flags
        leftFlag.layer.cornerRadius = 10
        rightFlag.layer.cornerRadius = 10
        leftFlag.layer.borderWidth = 1.0
        rightFlag.layer.borderWidth = 1.0
        
        //make the flags to appear by NSUser defaults
        if let row = UserDefaults.standard.value(forKey: "0") as? Int{
            pickerView.selectRow(row, inComponent: 0, animated: false)
            setFlag(leftFlag, row)
            
        }else{
            pickerView.selectRow(0, inComponent: 0, animated: false)
            setFlag(leftFlag, 0)
        }
        if let row = UserDefaults.standard.value(forKey: "1") as? Int{
            pickerView.selectRow(row, inComponent: 1, animated: false)
            setFlag(rightFlag, row)
        }else{
            pickerView.selectRow(0, inComponent: 1, animated: false)
            setFlag(rightFlag, 0)
        }
        
        getRate()
        appUser.getProfile(view: view, activity: activity)
        appUser.getTheBidsIds()
        appUser.completion = appUserCompletion
    }
    
    func addActivityIndicator(){
        DispatchQueue.main.async {
            self.activity.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.activity)
            self.view.centerXAnchor.constraint(equalTo: self.activity.centerXAnchor).isActive = true
            self.view.centerYAnchor.constraint(equalTo: self.activity.centerYAnchor).isActive = true
            self.activity.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.activity.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.activity.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.activity.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            //self.activity.widthAnchor.constraint(equalToConstant: 100).isActive = true
            //self.activity.activityIndicatorViewStyle =
            self.activity.activityIndicatorViewStyle = .whiteLarge
            self.activity.backgroundColor = UIColor(white: 0, alpha: 0.25)
            //self.activity.sizeThatFits(CGSize(width: 80, height: 80))
            self.activity.startAnimating()
        }
    }
    
    func stopAcivityIndicator(){
        activity.stopAnimating()
        activity.removeFromSuperview()
        activity.stopAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //We should not make the button make offer avaliable
        makeOfferItem.isEnabled = false
        //subscibe to notifications in order to move the view up or down
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: #selector(keyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: #selector(keyboardDidHide))
    }
    

    func appUserCompletion(_ success: Bool){
        //Once we got a good location, we stop the location manager and only record signifcant changes. This should save a the battery 
        appUser.stopLocationManager()
        appUser.getLocation(viewController: self, highAccuracy: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    deinit{
        //erase this
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    //MARK: -Actions
    @IBAction func browseOffer(_ sender: UIBarButtonItem) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "BrowseOffer", sender: sender)
        }

    }
   
    
    @IBAction func makeOffer(_ sender: Any) {
        appUser.getLocation(viewController: self, highAccuracy: true)
        offerViewOnScreen = true
        leftTextField.resignFirstResponder()
        rightTextField.resignFirstResponder()
        performSegue(withIdentifier: "OfferView", sender: nil)
    }
    
   
    @IBAction func myBids(_ sender: UIBarButtonItem) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "BrowseOffer", sender: sender)
        }
    }
    
   
    
    
    @IBAction func goToMenu(_ sender: Any) {
        
        DispatchQueue.main.async {
            let menuAndDimming = MenuAndDimming(frame: .zero)
            menuAndDimming.inquiryViewController = self
            menuAndDimming.showBlackView()
        }
    }
    
    func presentMakeProfileVC(){
        performSegue(withIdentifier: "MakeProfile", sender: nil)
    }
   
    
    //add the done buton to the keyboad code found on stackoverflow http://stackoverflow.com/questions/28338981/how-to-add-done-button-to-numpad-in-ios-8-using-swift
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        leftTextField.inputAccessoryView = doneToolbar
        rightTextField.inputAccessoryView = doneToolbar
        
        
    }
    
    @objc func doneButtonAction() {
        leftTextField.resignFirstResponder()
        rightTextField.resignFirstResponder()
    }
    
    func setFlag(_ imageView: UIImageView, _ row: Int){
        let leftCurrency = arrayOfCurrencies[row] //the left currency and right are equal
        imageView.image = UIImage(named: leftCurrency) //images are 100X53 pixels

    }
    
    //we get the rates of the selected currencies
    func getRate() {
        addActivityIndicator()
        leftTextField.text = ""
        rightTextField.text = ""
        self.leftLabel.text = ""
        self.rightLabel.text = ""
        let sellCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 0)]
        let buyCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 1)]
        
        
        let url = yahooClient.yahooURLFromParameters(sellCurrency + buyCurrency)
        yahooClient.performSearch(for: url){ success in
            
            guard success else{
                self.showAlert(alertTitle: NSLocalizedString("Network Error", comment: "Network Error: alertTitle, inquiryController"), alertMessage: NSLocalizedString("The rate of change could not be retrieved", comment: "The rate of change could not be retrived: message alert inquiryViewController"), actionTitle: NSLocalizedString("OK", comment: "OK: actionTitle"))
                self.stopAcivityIndicator()
                self.makeOfferItem.isEnabled = false
                return
            }
            
            
            switch self.yahooClient.rate!{
            case _ where self.yahooClient.rate! > 1:
                self.leftLabel.text = "1\n" + sellCurrency
                self.rightLabel.text = String(format: "%.2f\n", self.roundTwoDecimals(self.yahooClient.rate!)) + " " + buyCurrency
            case _ where self.yahooClient.rate! < 1:
                self.leftLabel.text = String(format: "%.2f\n", self.roundTwoDecimals(1/self.yahooClient.rate!)) + " " + sellCurrency
                self.rightLabel.text = "1\n" + buyCurrency
            case 1:
                self.leftLabel.text = "1\n" + sellCurrency
                self.rightLabel.text = "1\n" + buyCurrency
            default:
                print("there was an error")
                break
            }
            self.stopAcivityIndicator()
        }
        
        
    }
    
    func roundTwoDecimals(_ x: Float)-> Float{
        let y = roundf(100*x)/100
        return y
    }
    
    func showAlert(alertTitle: String, alertMessage: String, actionTitle:String ){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle, style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
  
    override var prefersStatusBarHidden: Bool{
        return offerViewOnScreen
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OfferView"{

            let sellCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 0)]
            let buyCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 1)]
            let per = NSLocalizedString(" per 1 ", comment: " per 1 ")
            let offerViewController = segue.destination as! OfferViewController
            offerViewController.isCounterOffer = false 
            offerViewController.user = self.user
            offerViewController.formatterSell = formatterByCode(sellCurrency)
            offerViewController.formatterBuy = formatterByCode(buyCurrency)
            offerViewController.quantitySell = leftTextField.text
            offerViewController.quantityBuy = rightTextField.text
            offerViewController.yahooRate = self.yahooClient.rate
            offerViewController.yahooCurrencyRatio = buyCurrency + per + sellCurrency
            offerViewController.sellLastEdit = sellLastEdit
            offerViewController.buyLastEdit = buyLastEdit
            offerViewController.inquiryViewController = self
            switch yahooClient.rate!{
                
            case _ where self.yahooClient.rate! > 1:
                
                offerViewController.userRate = roundTwoDecimals(yahooClient.rate!)
                offerViewController.currencyRatio =  buyCurrency + per + sellCurrency
            case _ where self.yahooClient.rate! < 1:
                offerViewController.userRate = roundTwoDecimals(1/yahooClient.rate!)
                offerViewController.currencyRatio = sellCurrency + per + buyCurrency
            case 1:
                offerViewController.userRate = 1.00
                offerViewController.currencyRatio = buyCurrency + per + sellCurrency
            default:
                print("there was an error")
                break
            }

        }else if segue.identifier == "BrowseOffer"{
            
            guard let sender = sender! as? UIBarButtonItem else{
                return
            }
            let browseNavigationController = segue.destination as! UINavigationController
            let browseOffersViewController = browseNavigationController.viewControllers.first as! BrowseOffersViewController
            
            if sender.action?.description == "browseOffer:"{
                browseOffersViewController.currentTable = .browseOffers
                let sellCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 0)]
                let buyCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 1)]
                browseOffersViewController.lookingToBuy = buyCurrency
                browseOffersViewController.lookingToSell = sellCurrency
            }else{
                browseOffersViewController.currentTable = .myBids
            }
        }
    }
    
}


extension InquiryViewController:UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let array = [arrayOfCurrencies.count, arrayOfCurrencies.count]
        
        return array[component]
    }
    
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        switch component{
        case 0:
            UserDefaults.standard.set(row, forKey: "0")
        case 1:
            UserDefaults.standard.set(row, forKey: "1")
        default:
            break
        }
        
        switch component{
        case 0:
            //making sure the UI components run in the main queque
            DispatchQueue.main.async {
                self.leftFlag.alpha = 0.2
                self.rightFlag.alpha = 0.2
                UIView.animate(withDuration: 1.5, animations:{
                    self.rightFlag.alpha = 1
                    self.leftFlag.alpha = 1
                    self.leftFlag.image = UIImage(named: self.arrayOfCurrencies[row])
                }, completion: nil)
            }
            getRate()

        case 1:
            DispatchQueue.main.async{
                self.leftFlag.alpha = 0.2
                self.rightFlag.alpha = 0.2
                UIView.animate(withDuration: 1.5, animations:{
                    self.rightFlag.alpha = 1
                    self.leftFlag.alpha = 1
                    self.rightFlag.image = UIImage(named: self.arrayOfCurrencies[row])
                }, completion: nil)
            }
            getRate()
            
        default:
            break
        }
    }
    
    func formatterByCode(_ currencyCode: String)-> NumberFormatter{
        let formatter = NumberFormatter()
        //formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency
        //formatter.currencySymbol = ""
        formatter.currencyCode = currencyCode
        
        return formatter
    }
    
}

extension InquiryViewController: UIPickerViewDelegate{
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string = arrayOfCurrencies[row]
        let attributedString = NSAttributedString(string: string, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        return attributedString
    }
}


extension InquiryViewController: UITextFieldDelegate{
    
    func disableTextField(_ textField: UITextField){
        textField.isEnabled = false
        textField.text = ""
        textField.backgroundColor = UIColor.black
        textField.alpha = 0.5
    }
    
    func enableTextField(_ textField: UITextField){
        textField.isEnabled = true
        textField.backgroundColor = UIColor.white
        textField.alpha = 1
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        makeOfferItem.isEnabled = false
        
        textField.text = ""
        
        switch textField{
        case leftTextField:
            disableTextField(rightTextField)
        case rightTextField:
            disableTextField(leftTextField)
        default:
            break
        }
    }
    
    
    //we use this function to calculate and display the proportional amount on the other text field
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        
        let sellCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 0)]
        let buyCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 1)]
        
        guard textField.text! != "" else{
            enableTextField(leftTextField)
            enableTextField(rightTextField)
            return
        }
        
        //quantity could be either in the right or left textfield
        guard let quantity = Float(textField.text!) else{
            print("the input needs to be a number")
            showAlert(alertTitle: NSLocalizedString("Input Error", comment: "Input Error: alertTitle in inquiryView"), alertMessage: NSLocalizedString("The input needs to be a number", comment:"The input needs to be a number: alert message, inquiry viewController"), actionTitle: NSLocalizedString("Try Again", comment: "Try Again: action title, inquiryViewController"))
            return
        }

        switch textField{
        case leftTextField:
            sellLastEdit = true
            buyLastEdit = false
            enableTextField(rightTextField)
            guard let rate = self.yahooClient.rate else{
                print("there is no rate ")
                return
            }
            //formater for buyCurrency
            let formatterBuy = formatterByCode(buyCurrency)
            rightTextField.text = formatterBuy.string(from: self.roundTwoDecimals(rate*quantity) as NSNumber)
            let formatterSell = formatterByCode(sellCurrency)
            //this will give the symbol to the text in the texfield that was just edited
            guard let number = Float(leftTextField.text!)  else{
                return
            }
            
            leftTextField.text = formatterSell.string(from: number as NSNumber)
        
        case rightTextField:
            sellLastEdit = false
            buyLastEdit = true
            enableTextField(leftTextField)
            guard let rate = self.yahooClient.rate else{
                print("there is no rate ")
                return
            }
            
            //formater for sellCurrency
            let formatterSell = formatterByCode(sellCurrency)
            leftTextField.text = formatterSell.string(from: self.roundTwoDecimals(quantity/rate) as NSNumber)
            let formatterBuy = formatterByCode(buyCurrency)
            //this will give the symbol to the text in the texfield that was just edited
            guard let number = Float(rightTextField.text!)  else{
                return
            }
            
            rightTextField.text = formatterBuy.string(from: number as NSNumber)
            
        default:
            break
        }
        
        // if the yahooClient.rate is nil we keep the make offer unabailable
        if let _ = yahooClient.rate{
            makeOfferItem.isEnabled = true
        }else{
            makeOfferItem.isEnabled = false
        }

    }
    
    //The function lets the keyboard hide when return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func resignIfFirstResponder(_ textField: UITextField) {
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

    
    @objc func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen && view.frame.origin.y == 0{
            view.frame.origin.y -= keyboardHeight(notification)
            
        }
        
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen && view.frame.origin.y != 0 {
            view.frame.origin.y = 0
            
        }
    }
    
    @objc func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true

    }
    
    @objc func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
    }
    
    fileprivate func subscribeToNotification(_ notification: String, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    fileprivate func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}


