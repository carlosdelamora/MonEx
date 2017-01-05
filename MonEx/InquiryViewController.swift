//
//  InquiryViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/3/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class InquiryViewController: UIViewController {
    
    let arrayOfCurrencies = [ NSLocalizedString("Colombian Peso", comment: "Colombian Peso: to appear in the picker, inquiryController"), NSLocalizedString("Canadian Dollar", comment: "Canadian Dollar: to appear in the picker, inquiryController"), NSLocalizedString("Dollars", comment: "Dollars: to appear in the picker, inqueiryController"), NSLocalizedString("Euro", comment: "Euro: to appear in the picker, inquiryController"), NSLocalizedString("Mexican Peso", comment: "Mexican Peso: to appear in the picker, inquiry Controller"), NSLocalizedString("Brithish Pound", comment: "Brithish Pound: to appear in the picker, inquiry Controller"), NSLocalizedString("Australian Dollar", comment: "Australian Dollar: to appear in the picker, inquiryController")]
    
    @IBOutlet weak var pickerView: UIPickerView!
    //We use this array to populate the picker View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Picker Set up 
        pickerView.delegate = self
        pickerView.dataSource = self
        

        
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
}

extension InquiryViewController: UIPickerViewDelegate{
    
}
