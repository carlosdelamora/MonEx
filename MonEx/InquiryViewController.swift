//
//  InquiryViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/3/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase
import GoogleSignIn
import CoreData
import FBSDKLoginKit

class InquiryViewController: UIViewController {
    
    var keyboardOnScreen = false
    var offerViewOnScreen = false
    var yahooClient = YahooClient()
    var user: FIRUser?
    var context: NSManagedObjectContext? = nil
    let appUser = AppUser.sharedInstance
    
    override var shouldAutorotate: Bool{
        return false
    }
   
    
    //We use this array to populate the picker View
    let arrayOfCurrencies = [Constants.currency.ARS, Constants.currency.AUD,Constants.currency.BRL, Constants.currency.CAD,Constants.currency.COP,Constants.currency.EUR, Constants.currency.GBP, Constants.currency.MXN,Constants.currency.USD]
    
    @IBOutlet weak var sellLabel: UILabel!
    @IBOutlet weak var buyLabel: UILabel!
    
    
    
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
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //subscibe to notifications in order to move the view up or down
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: #selector(keyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: #selector(keyboardDidHide))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        appUser.getLocation(viewController: self, highAccuracy: false)
        appUser.getProfile()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    deinit{
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
        
    @IBAction func browseOffers(_ sender: Any) {
        performSegue(withIdentifier: "BrowseOffer", sender: nil)
    }
    
    @IBAction func makeOffer(_ sender: Any) {
        offerViewOnScreen = true
        leftTextField.resignFirstResponder()
        rightTextField.resignFirstResponder()
        performSegue(withIdentifier: "OfferView", sender: nil)
    }
    
    
    @IBAction func logOutTemporary(_ sender: Any) {
        appUser.clear()
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        GIDSignIn.sharedInstance().signOut()
       
        
        self.dismiss(animated: true, completion: nil)

    }
    
    
    
    @IBAction func goToMenu(_ sender: Any) {
        
        let menuAndDimming = MenuAndDimming(frame: .zero)
        menuAndDimming.inquiryViewController = self       
        menuAndDimming.showBlackView()
        
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
    
    func doneButtonAction() {
        leftTextField.resignFirstResponder()
        rightTextField.resignFirstResponder()
    }
    
    func setFlag(_ imageView: UIImageView, _ row: Int){
        let leftCurrency = arrayOfCurrencies[row] //the left currency and right are equal
        imageView.image = UIImage(named: leftCurrency) //images are 100X53 pixels

    }
    
    //we get the rates of the selected currencies
    func getRate() {
        
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
                
                self.makeOfferItem.isEnabled = false
                return
            }
            
            self.makeOfferItem.isEnabled = true
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
            
            
            let offerViewController = segue.destination as! OfferViewController
            offerViewController.user = self.user
            offerViewController.formatterSell = formatterByCode(sellCurrency)
            offerViewController.formatterBuy = formatterByCode(buyCurrency)
            offerViewController.quantitySell = leftTextField.text
            offerViewController.quantityBuy = rightTextField.text
            offerViewController.yahooRate = self.yahooClient.rate
            offerViewController.yahooCurrencyRatio = buyCurrency + " per 1 " + sellCurrency
            switch yahooClient.rate!{
                
            case _ where self.yahooClient.rate! > 1:
                
                offerViewController.userRate = roundTwoDecimals(yahooClient.rate!)
                offerViewController.currencyRatio =  buyCurrency + " per 1 " + sellCurrency
            case _ where self.yahooClient.rate! < 1:
                offerViewController.userRate = roundTwoDecimals(1/yahooClient.rate!)
                offerViewController.currencyRatio = sellCurrency + " per 1 " + buyCurrency
            case 1:
                offerViewController.userRate = 1.00
                offerViewController.currencyRatio = buyCurrency + " per 1 " + sellCurrency
            default:
                print("there was an error")
                break
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
    
    /*func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return arrayOfCurrencies[row]
    }*/

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string = arrayOfCurrencies[row]
        let attributedString = NSAttributedString(string: string, attributes: [NSForegroundColorAttributeName: UIColor.white])
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

    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen && view.frame.origin.y == 0{
            view.frame.origin.y -= keyboardHeight(notification)
            
        }
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen && view.frame.origin.y != 0 {
            view.frame.origin.y = 0
            
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true

    }
    
    func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
    }
    
    fileprivate func subscribeToNotification(_ notification: String, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name(rawValue: notification), object: nil)
    }
    
    fileprivate func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}


