//
//  LoginViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    
    
    @IBAction func signInButton(_ sender: Any) {
        signInStatus(true)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        // Do any additional setup after loading the view.
        //as of now everyone is signed in 
        signInStatus(true)
    }

    
    
    fileprivate func configureUI() {
        
        // configure background gradient
        let backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [Constants.UI.LoginColorTop, Constants.UI.LoginColorBottom]
        backgroundGradient.locations = [0, 1]
        backgroundGradient.frame = view.frame
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }
    
    func signInStatus(_ isSignedIn: Bool){
        
        if isSignedIn{
            performSegue(withIdentifier: "Inquiry", sender: nil)
        }
    }

  
}
