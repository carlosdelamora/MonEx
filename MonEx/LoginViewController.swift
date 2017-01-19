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
//import FirebaseGoogleAuthUI
import GoogleSignIn

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
        
        //the configureAuth method perfomrms the segue one the user is authenticated
        configureAuth()
        
        //make the corners round of the sign in button
        signInButton.layer.cornerRadius = 2
        
        setFacebookAndGoogleButton()
        configureUI()
        
    }

 
    
    @IBAction func signInButton(_ sender: Any) {
        
        
        signWithEmail()
        print("current user \(FIRAuth.auth()?.currentUser)")
    }
    
    func signWithEmail(){
        
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
                case 17008:
                    self.wrongFormat()
                    return
                case 17011:
                    self.notRegisteredAlert()
                case 17009:
                    self.wrongPassword()
                    return
                case -1009, 17020:
                    self.networkError()
                    return
                default:
                    return
                }
            }
            self.user = user
        }
    }
    

    fileprivate func setFacebookAndGoogleButton(){
        
        //set the facebook login button and delegate
        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["email", "public_profile"]//get the email on firebase
        loginButton.delegate = self
        //let margins = view.layoutMarginsGuide
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginButton)
        loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 42).isActive = true
        loginButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        
        //set google login button and delegate
        let googleButton = GIDSignInButton()
        //we need to add the sub view before setting the constrains
        view.addSubview(googleButton)
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4).isActive = true
        googleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant:  -4).isActive = true
        loginButton.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 8).isActive = true
        //google delegate
        GIDSignIn.sharedInstance().uiDelegate = self
        //GIDSignIn.sharedInstance().signIn()
        
    }
    
    
    
    //MARK: error handling
    func wrongFormat(){
        let alert = UIAlertController(title: NSLocalizedString("Wrong Format", comment:"Wrong Format: login viewController"), message: NSLocalizedString("Email is in the wrong format", comment: "Email is in the wrong format: loginViewController"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: login view controller after wrong password error"), style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    
    func notRegisteredAlert(){
        
        let alert = UIAlertController(title: NSLocalizedString("Not registered", comment: "Not registered: in the login view controller"), message: NSLocalizedString("There us no registered user with the given user email and password. Would you like to register?", comment: "There us no registered user with the given user email and password. Would you like to register?; login view controller") , preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Canel", comment: "Canel:loginViewController"), style: .cancel){ action in
    
        }
        alert.addAction(cancelAction)
        
        let registerAction = UIAlertAction(title: NSLocalizedString("Register", comment: "Register: loginViewController"), style: .default){ action in
            
            guard let email = self.emailTextField.text, let password = self.passwordTextField.text else{
                print("form is not valid return ")
                return
            }
            
            FIRAuth.auth()?.createUser(withEmail: email, password: password){ (user, error) in

                if error != nil{
                    print("error \(error)")
                    
                    guard let error = error as? NSError else{
                        return
                    }
                    
                    switch error.code{
                    case 17008:
                        self.wrongFormat()
                        return
                    case -1009, 17020:
                        self.networkError()
                        return
                    default:
                        return
                    }
                }
                // if there is no error asign the user to self.user
                self.user = user
                
                FIRAuth.auth()?.currentUser?.sendEmailVerification(completion: { (error) in
                    
                    guard error == nil else {
                        print("we got error with the email")
                        return
                    }
                    
                    print("we sent verification")
                })
                
                print("the user \(user?.uid) is email verified \(user?.isEmailVerified)")
                print("succesfully authenticated the user ")
            }

        }
        
        alert.addAction(registerAction)
        present(alert, animated: true)
    }
    
    func wrongPassword(){
        
        let alert = UIAlertController(title: NSLocalizedString("Wrong Password", comment:"wrong password"), message: NSLocalizedString("Plase try again with a different password", comment: "Plase try again with a different password: login viewController"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: login view controller after wrong password error"), style: .default, handler: nil)
            alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func networkError(){
        
        let alert = UIAlertController(title: NSLocalizedString("Network Error", comment: "Netwrok Error: login view controller"), message: NSLocalizedString("Make sure you are connected to the internet", comment: "Make sure you are connected to the internet: loginViewController"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: login view Controller notwerk collection"), style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func unkownError(){
        let alert = UIAlertController(title: NSLocalizedString("Unkown Error", comment:"Unkown Error"), message: "Unable to login, plase try again latter.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: login view controller unkown error"), style: .default, handler: nil)
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
            
            if !(user?.isEmailVerified)!{
                DispatchQueue.main.async {
                    self.notEmailVerifiedAlert()
                }
                
            }else{
                print("perform segue")
                configureDatabase()
                performSegue(withIdentifier: "Inquiry", sender: nil)
            }
        }
    }
    
    func notEmailVerifiedAlert(){
        let alert = UIAlertController(title: NSLocalizedString("Email not verified", comment: "Email not verified: in the login view controller"), message: NSLocalizedString("An email verification has been sent, click \"OK\" once the email has been verified", comment: "An email verification has been sent, click \"OK\" once the email has been verified: login view controller") , preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Canel", comment: "Canel:loginViewController"), style: .cancel){ action in
            //if the action gets canceled that means the new user should not be registered so we erase it. Once we erase the user the observer notices the change in auth and the Bool isSigned in changes to false. This way we get out of the loop showing the alert notEmailVerifiedAlert
            self.user?.delete(completion: { (error) in
                
                if let error = error{
                    print("we were unable to delete the user because of error \(error)")
                }else{
                    print("user was deleted because we where unable to verify the email")
                }
            })
        }
        alert.addAction(cancelAction)
        
        let registerAction = UIAlertAction(title: "OK", style: .default){ action in
            
            //we fall in a loop until the email is verified or cancel is pressed
            FIRAuth.auth()?.currentUser?.reload { (err) in
                if err == nil{
                    
                    if !(self.user?.isEmailVerified)!{
                        DispatchQueue.main.async {
                            self.notEmailVerifiedAlert()
                        }
                    }else{
                        self.signWithEmail()
                    }
                }
            }
            
            
        }
        
        alert.addAction(registerAction)
        present(alert, animated: true)
    }
    
    func configureAuth(){
        //listen to changes in the authorization state
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener{ (auth, user) in
            
            //check if there is a current user
            if let activeUser = user{
                //check if the active user is the current Firebase user
                if self.user != activeUser {
                    self.user = activeUser
                    
                    self.signInStatus(true)
                    print("we try to sign in")
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
        
        guard let current = FBSDKAccessToken.current() else{
            return
        }
       
        guard let tokenString = current.tokenString else{
            return
        }
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: tokenString)
        FIRAuth.auth()?.signIn(with: credential){ (user, error) in
            if let error = error {
                print("there was an error \(error)")
                return
            }else{
                guard let user = user else {
                    return
                }
                print("\(user)")
            }
        }
        print("successfully loged in to facebook")
    }
  
    
}

extension LoginViewController:  GIDSignInUIDelegate{
    
    
    
}


