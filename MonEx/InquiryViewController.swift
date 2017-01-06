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
    let arrayOfCurrencies = [ NSLocalizedString("COP", comment: "Colombian Peso: to appear in the picker, inquiryController"), NSLocalizedString("CAD", comment: "Canadian Dollar: to appear in the picker, inquiryController"), NSLocalizedString("USD", comment: "Dollars: to appear in the picker, inqueiryController"), NSLocalizedString("EUR", comment: "Euro: to appear in the picker, inquiryController"), NSLocalizedString("MXN", comment: "Mexican Peso: to appear in the picker, inquiry Controller"), NSLocalizedString("GBP", comment: "Brithish Pound: to appear in the picker, inquiry Controller"), NSLocalizedString("AUD", comment: "Australian Dollar: to appear in the picker, inquiryController")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Picker Set up
        pickerView.delegate = self
        pickerView.dataSource = self
        //textField Delegate set up
        leftTextField.delegate = self
        rightTextField.delegate = self
        
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
        
        //set the style of the button 
        getRateButton.layer.cornerRadius = 10
        getRateButton.setTitle(NSLocalizedString("Get Exchange Rate", comment: "Get Exchange Rte: titile in the button get exchange rate, inquiryViewController"), for: .normal)
        getRateButton.backgroundColor = UIColor(red: 0, green: 0.5, blue: 0.7, alpha: 1)
        getRateButton.layer.borderWidth = 1
        
        leftFlag.image = UIImage(named: "GBP")
        rightFlag.image = UIImage(named: "EUR")

    }

    @IBOutlet weak var leftFlag: UIImageView!
    @IBOutlet weak var rightFlag: UIImageView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var leftTextField: UITextField!
    @IBOutlet weak var rightTextField: UITextField!
    @IBOutlet weak var getRateButton: UIButton!

    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    //we get the rates of the selected currencies
    @IBAction func getRate(_ sender: Any) {
        
        let sellCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 0)]
        let buyCurrency = arrayOfCurrencies[pickerView.selectedRow(inComponent: 1)]
        
        
        let url = yahooClient.yahooURLFromParameters(sellCurrency + buyCurrency)
        yahooClient.performSearch(for: url){ success in
            
            guard success else{
                return
            }
            
            switch self.yahooClient.rate!{
            case _ where self.yahooClient.rate!>=1:
                self.leftLabel.text = "1 " + sellCurrency
                self.rightLabel.text = "\(self.roundTwoDecimals(self.yahooClient.rate!)) " + buyCurrency
            case _ where self.yahooClient.rate!<1:
                self.leftLabel.text = "\(self.roundTwoDecimals(1/self.yahooClient.rate!)) " + sellCurrency
                self.rightLabel.text = "1 " + buyCurrency
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
            leftFlag.image = UIImage(named:arrayOfCurrencies[row])
            
        case 1:
            rightFlag.image = UIImage(named:arrayOfCurrencies[row])
        default:
            break
        }
    }
    
    
}

extension InquiryViewController: UIPickerViewDelegate{
    
    
    
}


extension InquiryViewController: UITextFieldDelegate{
    
    //The function lets the keyboard hide when return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen && view.frame.origin.y == 0{
            view.frame.origin.y -= 250
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
    
    
    fileprivate func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    
}
