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
import FBSDKLoginKit

class LoginViewController: UIViewController {

    
    var rootReference:FIRDatabaseReference! //TODO: check if we need this 
    fileprivate var _authHandle: FIRAuthStateDidChangeListenerHandle!
    var user: FIRUser?
    var displayName = "Anonymous"

    
 
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    
    deinit {
        FIRAuth.auth()?.removeStateDidChangeListener(_authHandle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAuth()
        
        //make the corners round of the sign in button
        signInButton.layer.cornerRadius = 5
        
        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["email", "public_profile"]//get the email on firebase
        loginButton.delegate = self
        //let margins = view.layoutMarginsGuide
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginButton)
        loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        loginButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 44).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        configureUI()
        
    }

    
    
    @IBAction func signInButton(_ sender: Any) {
        
        guard let email = emailTextField.text, let password = passwordTextField.text else{
            print("form is not valid return ")
            return
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password){ (user, error) in
        
            if error != nil{
                
                print("error \(error)")
                
                guard let error = error as? NSError else{
                    return
                }
                
                switch error.code{
                case 17011:
                    self.notRegisteredAlert()
                case 17009:
                    self.wrongPassword()
                default:
                    return
                }
                
                
            }
        }
        
        print("current uder \(FIRAuth.auth()?.currentUser)")
        //signInStatus(true)
    }

    func notRegisteredAlert(){
        
        let alert = UIAlertController(title: NSLocalizedString("Not registered", comment: "Not registered: in the login view controller"), message: NSLocalizedString("There us no registered user with the given user email and password. Would you like to register?", comment: "There us no registered user with the given user email and password. Would you like to register?; login view controller") , preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Canel", style: .cancel){ action in
    
        }
        alert.addAction(cancelAction)
        
        let registerAction = UIAlertAction(title: "Register", style: .default){ action in
            
            guard let email = self.emailTextField.text, let password = self.passwordTextField.text else{
                print("form is not valid return ")
                return
            }

            FIRAuth.auth()?.createUser(withEmail: email, password: password){ (user, error) in
                
                if error != nil{
                    
                    print("error \(error)")
    
                }
                
                print("succesfully authenticated the user ")
            }

        }
        
        alert.addAction(registerAction)
        present(alert, animated: true)
    }
    
    func wrongPassword(){
        
        let alert = UIAlertController(title: NSLocalizedString("Wrong Password", comment:"wrong password"), message: NSLocalizedString("Plase try again with a different password", comment: "Plase try again with a different password: login viewController"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: login view COntroller afte wrong password error"), style: .default, handler: nil)
            alert.addAction(okAction)
        present(alert, animated: true)
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
    
    func configureAuth(){
        //listen to changes in the authorization state
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener{ (auth, user) in
            
            //check if there is a current user
            if let activeUser = user{
                //check if the active user is the current Firebase user
                if self.user != activeUser {
                    self.user = activeUser
                    //self.signInStatus(true)
                }
                
            }else{
                //there is no FIRUser, the user needs to sign in 
                self.signInStatus(false)
            }
        }
    }
    
    func configureDatabase(){
        rootReference = FIRDatabase.database().reference()
    }
    
}

//Facebook Delegate
extension LoginViewController: FBSDKLoginButtonDelegate {
    

    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print("There was an error \(error)")
            return
        }
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        FIRAuth.auth()?.signIn(with: credential){ (user, error) in
            
            if let error = error {
                
                print("there was an error \(error)")
                return
            }else{
                print("\(user!)")
            }
            
            
        }
        print("successfully loged in to facebook")
        //print("\(FIRAuth.auth()?.currentUser?.uid)")
    }
  

}

