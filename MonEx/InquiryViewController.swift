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
        
        leftFlag.image = UIImage(named: "GBP")
        rightFlag.image = UIImage(named: "EUR")

    }

    @IBOutlet weak var leftFlag: UIImageView!
    
    @IBOutlet weak var rightFlag: UIImageView!
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    @IBOutlet weak var leftTextField: UITextField!
    
    @IBOutlet weak var rightTextField: UITextField!
    
    

    
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
    
    // the function returns the height of the keyboard and deterimens the displacement need it by the view to not cover the text fields
    fileprivate func keyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
        }
        
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
            
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
