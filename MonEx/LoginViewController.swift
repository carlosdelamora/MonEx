//
//  LoginViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/7/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//
import Firebase
import UIKit
import FirebaseAuthUI

class LoginViewController: UIViewController {

    
    var rootReference:FIRDatabaseReference! //TODO: check if we need this 
    fileprivate var _authHandle: FIRAuthStateDidChangeListenerHandle!
    var user: FIRUser?
    var displayName = "Anonymous"

    
    @IBAction func signInButton(_ sender: Any) {
        signInStatus(true)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
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
            configureDatabase()
            performSegue(withIdentifier: "Inquiry", sender: nil)
            
        }
    }
    
    func configureDatabase(){
        rootReference = FIRDatabase.database().reference()
    }
  
}


