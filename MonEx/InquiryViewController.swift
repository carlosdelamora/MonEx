//
//  InquiryViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/3/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit


class InquiryViewController: UIViewController {
    
    var keyboardOnScreen = false
    var yahooClient = YahooClient()
    
    //We use this array to populate the picker View
    let arrayOfCurrencies = [ NSLocalizedString("AUD", comment: "Australian Dollar: to appear in the picker, inquiryController"), NSLocalizedString("COP", comment: "Colombian Peso: to appear in the picker, inquiryController"), NSLocalizedString("CAD", comment: "Canadian Dollar: to appear in the picker, inquiryController"), NSLocalizedString("EUR", comment: "Euro: to appear in the picker, inquiryController"), NSLocalizedString("GBP", comment: "Brithish Pound: to appear in the picker, inquiry Controller"), NSLocalizedString("MXN", comment: "Mexican Peso: to appear in the picker, inquiry Controller"), NSLocalizedString("USD", comment: "Dollars: to appear in the picker, inqueiryController")]
    
    
    @IBOutlet weak var sellLabel: UILabel!
    @IBOutlet weak var buyLabel: UILabel!
    
    
    
    @IBOutlet weak var leftFlag: UIImageView!
    @IBOutlet weak var rightFlag: UIImageView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var leftTextField: UITextField!
    @IBOutlet weak var rightTextField: UITextField!
    
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    
    
    @IBAction func makeOffer(_ sender: Any) {
        leftTextField.resignFirstResponder()
        rightTextField.resignFirstResponder()
        performSegue(withIdentifier: "OfferView", sender: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unsubscribeFromAllNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set the labels
        sellLabel.text = NSLocalizedString("SELL", comment: "SELL: top label inquiryController")
        buyLabel.text = NSLocalizedString("BUY", comment: "BUY: top label inquiryController")
        sellLabel.font = UIFont(name: ".SFUIDisplay-Bold" , size: 30)
        buyLabel.font = UIFont(name: ".SFUIDisplay-Bold" , size: 30)
        
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

        //subscibe to notifications in order to move the view up or down
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: #selector(keyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: #selector(keyboardDidHide))
        
        //set round edges for the flags
        leftFlag.layer.cornerRadius = 10
        rightFlag.layer.cornerRadius = 10
        leftFlag.layer.borderWidth = 1.0
        rightFlag.layer.borderWidth = 1.0
        
        //TODO: make the flags to appear by NSUser defaults
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
        let leftCurrency = arrayOfCurrencies[row]
        imageView.image = UIImage(named: leftCurrency)

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
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OfferView"{
            
            let sellCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 0)]
            let buyCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 1)]
            
            
            let offerViewController = segue.destination as! OfferViewController
            offerViewController.sellCurrency = sellCurrency
            offerViewController.buyCurrency = buyCurrency
            offerViewController.quantitySell = leftTextField.text
            offerViewController.quantityBuy = rightTextField.text
            
            switch yahooClient.rate!{
            case _ where self.yahooClient.rate! > 1:
                
                offerViewController.rate = "\(roundTwoDecimals(yahooClient.rate!))"
                offerViewController.currencyRatio =  buyCurrency + " per 1 " + sellCurrency
            case _ where self.yahooClient.rate! < 1:
                offerViewController.rate = "\(roundTwoDecimals(1/yahooClient.rate!))"
                offerViewController.currencyRatio = sellCurrency + " per 1 " + buyCurrency
            case 1:
                offerViewController.rate = "1"
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
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return arrayOfCurrencies[row]
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
    
    
}

extension InquiryViewController: UIPickerViewDelegate{
    
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
        textField.backgroundColor = UIColor.clear
        textField.alpha = 1
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
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
        
        guard textField.text! != "" else{
            enableTextField(leftTextField)
            enableTextField(rightTextField)
            return
        }
        
        //quantity could be either in the right or left textfield
        guard let quantity = Float(textField.text!)else{
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
            
            rightTextField.text = String(format: "%.2f", self.roundTwoDecimals(rate*quantity))
            
        case rightTextField:
            
            enableTextField(leftTextField)
            guard let rate = self.yahooClient.rate else{
                print("there is no rate ")
                return
            }
            
            leftTextField.text = String(format: "%.2f", self.roundTwoDecimals(quantity/rate))
            
        default:
            break
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


