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
import GoogleSignIn


class LoginViewController: UIViewController {

    
    var rootReference:FIRDatabaseReference!
    fileprivate var _authHandle: FIRAuthStateDidChangeListenerHandle!
    var user: FIRUser?
    var displayName = "Anonymous"
    var needsEmailVerification: Bool = false
    var keyboardOnScreen = false
    
    override var shouldAutorotate: Bool{
        return false
    }
    
    
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    
    deinit {
        FIRAuth.auth()?.removeStateDidChangeListener(_authHandle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //the configureAuth method perfomrms the segue once the user is authenticated
        configureAuth()
        
        //make the corners round of the sign in and register
        signInButton.layer.cornerRadius = 2
        registerButton.layer.cornerRadius = 2
        
        confirmPasswordTextField.isHidden = true
        setFacebookAndGoogleButton()
        configureUI()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //textField delegation and subscription to notifications
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        subscribeToNotification(NSNotification.Name.UIKeyboardWillShow.rawValue, selector: #selector(keyboardWillShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardWillHide.rawValue, selector: #selector(keyboardWillHide))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidShow.rawValue, selector: #selector(keyboardDidShow))
        subscribeToNotification(NSNotification.Name.UIKeyboardDidHide.rawValue, selector: #selector(keyboardDidHide))
        
        //change the keyboard for email 
        emailTextField.keyboardType = .emailAddress

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //I have this function only for debugging purposes 
    }
    
    
    
    @IBAction func signInButton(_ sender: Any) {
        signWithEmail()
        print("current user \(FIRAuth.auth()?.currentUser)")
    }
    
    
    @IBAction func registerButton(_ sender: Any) {
        if confirmPasswordTextField.isHidden{
            UIView.animate(withDuration: 0.5){
                self.confirmPasswordTextField.isHidden = false
            }
        }else if confirmPasswordTextField.text == passwordTextField.text{
            
            //create a user
            createUserWithEmail()
        }else{
            self.passwordNotConfirmed()
            print("the passwords do not agree")
        }
        
        
        
    }
    
    func createUserWithEmail(){
        
        guard let email = self.emailTextField.text, let password = self.passwordTextField.text else{
            print("form is not valid return ")
            return
        }
        
        self.needsEmailVerification = true
        FIRAuth.auth()?.createUser(withEmail: email, password: password){ (user, error) in
            
            if error != nil{
                print("error \(error)")
                self.needsEmailVerification = false
                guard let error = error as? NSError else{
                    return
                }
                
                switch error.code{
                case 17007:
                    self.emailAlreadyInUse()
                case 17026:
                    self.atLeast6Char()
                case 17008:
                    self.wrongFormat()
                    return
                case -1009, 17020:
                    self.networkError()
                    return
                default:
                    self.unkownError()
                    return
                }
                
            }else{
                // if there is no error asign the user to self.user
                self.user = user
                FIRAuth.auth()?.currentUser?.sendEmailVerification(completion: { (error) in
                    
                    guard error == nil else {
                        print("we got error with the email")
                        return
                    }
                    
                    print("we sent verification")
                })
            }
            print("the user \(user?.uid) is email verified \(user?.isEmailVerified)")
            print("succesfully authenticated the user ")
        }

    }
    
    
    func signWithEmail(){
        
        guard let email = emailTextField.text, let password = passwordTextField.text else{
            print("form is not valid return ")
            return
        }
        
        let credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
        signInWithCredential(credential)
    }
    
    func signInWithCredential(_ credential: FIRAuthCredential){
        FIRAuth.auth()?.signIn(with:credential){ (user, error) in
            
            if error != nil{
                
                print("error \(error)")
                
                guard let error = error as? NSError else{
                    return
                }
                
                switch error.code{
                case 17007:
                    self.emailAlreadyInUse()
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
                    self.unkownError()
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
        loginButton.removeConstraints(loginButton.constraints)
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
        
        
    }
    
    
    
    //MARK: error handling
    func notEmailVerifiedAlert(){
        let alert = UIAlertController(title: NSLocalizedString("Email not verified", comment: "Email not verified: in the login view controller"), message: NSLocalizedString("An email verification has been sent, click \"OK\" once the email has been verified", comment: "An email verification has been sent, click \"OK\" once the email has been verified: login view controller") , preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Canel", comment: "Canel:loginViewController"), style: .cancel){ action in
            //if the action gets canceled that means the new user should not be registered so we erase it. Once we erase the user the observer notices the change in auth and the Bool isSigned in changes to false. This way we get out of the loop showing the alert notEmailVerifiedAlert
            self.user?.delete(completion: { (error) in
                
                if let error = error{
                    print("we were unable to delete the user because of error \(error)")
                }else{
                    self.needsEmailVerification = false
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

    func passwordNotConfirmed(){
        let alert = UIAlertController(title: NSLocalizedString("Confirmation Error", comment:"Confirmation Error: login viewController"), message: NSLocalizedString("Passwords do not match:login viewController", comment: "Passwords do not match:login viewController"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: weak password alert"), style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func atLeast6Char(){
        let alert = UIAlertController(title: NSLocalizedString("Weak password", comment:"Weak password: login viewController"), message: NSLocalizedString("The password must be 6 characters long or more", comment: "The password must be 6 characters long or more"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: weak password alert"), style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    
    func emailAlreadyInUse(){
        let alert = UIAlertController(title: NSLocalizedString("Email Already In Use", comment:"Email Already In Use: login viewController"), message: NSLocalizedString("The email address is already in use by another account, try to sign in with your original account", comment: "The email address is already in use by another account, try to sign in with your original account: loginViewController"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: after the email is already in use alert"), style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    
    func wrongFormat(){
        let alert = UIAlertController(title: NSLocalizedString("Wrong Format", comment:"Wrong Format: login viewController"), message: NSLocalizedString("Email is in the wrong format", comment: "Email is in the wrong format: loginViewController"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK: login view controller after wrong password error"), style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func notRegisteredAlert(){
        
        let alert = UIAlertController(title: NSLocalizedString("Not registered", comment: "Not registered: in the login view controller"), message: NSLocalizedString("There is no registered user with the given user email and password. Please press register and confirm your password", comment: "There is no registered user with the given user email and password. Please press register and confirm your password: login view controller") , preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Canel", comment: "Canel:loginViewController"), style: .cancel){ action in
    
        }
        alert.addAction(cancelAction)
        
        let registerAction = UIAlertAction(title: NSLocalizedString("Register", comment: "Register: loginViewController"), style: .default){ action in
            
            self.registerButton(self)

        }
        alert.addAction(registerAction)
        present(alert, animated: true)
    }
    
    func wrongPassword(){
        
        let alert = UIAlertController(title: NSLocalizedString("Wrong Password", comment:"wrong password"), message: NSLocalizedString("Plase try again with a different password or if you have prevoiusly signed in with Google of Fecebook try signing in the same way", comment: "Plase try again with a different password or if you have prevoiusly signed in with Google of Fecebook try signing in the same way: login viewController"), preferredStyle: .alert)
        
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
        let alert = UIAlertController(title: NSLocalizedString("Unkown Error", comment:"Unkown Error"), message: NSLocalizedString("Unable to login, try to login with a different method", comment: "Unable to login, try to login with a different method"), preferredStyle: .alert)
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
    
    //MARK: signInStatusChanged
    func signInStatus(_ isSignedIn: Bool){
       
        if isSignedIn{

            //we need to verify the email before we let them go to inquiry view controller, needs EmailVerification should only be true when a user is created by email and password
            if !(user?.isEmailVerified)! && needsEmailVerification{
                DispatchQueue.main.async {
                    self.notEmailVerifiedAlert()
                }
                
            }else{
                print("perform segue")
                configureDatabase()
                let appUser = AppUser.sharedInstance
                appUser.imageId = (FIRAuth.auth()?.currentUser!.uid)!
                performSegue(withIdentifier: "Inquiry", sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Inquiry"{
            let inquiryController = segue.destination as! InquiryViewController
            inquiryController.user = self.user
        }
    }
    
    
    func configureAuth(){
        //listen to changes in the authorization state
        _authHandle = FIRAuth.auth()?.addStateDidChangeListener{ (auth, user) in
            
            //check if there is a current user
            if let activeUser = user{
                //check if the active user is the current Firebase user and that has been authenticated
                if self.user != activeUser{
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
        
        needsEmailVerification = false
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: tokenString)
        signInWithCredential(credential)
        print("successfully loged in to facebook")
    }
  
    
}

extension LoginViewController: UITextFieldDelegate{
    
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

extension LoginViewController:  GIDSignInUIDelegate{
    
}


