//
//  CreateProfileViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/20/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseStorage
import CoreData
import Firebase

class CreateProfileViewController: UIViewController, UINavigationControllerDelegate {
    
    var storageReference: FIRStorageReference!
    var context: NSManagedObjectContext? = nil
    var rootReference: FIRDatabaseReference!
    var user : FIRUser?
    let appUser = AppUser.sharedInstance
    var uploadingPicture: Bool = false
    var photosArray = [Profile]()
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    
    @IBOutlet weak var takePictureButton: UIButton!
    
    
    @IBOutlet weak var viewOfTexts: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldStyle(textField: nameTextField)
        textFieldStyle(textField: lastNameTextField)
        textFieldStyle(textField: emailTextField)
        textFieldStyle(textField: phoneNumberTextField)
        nameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        phoneNumberTextField.delegate = self
        phoneNumberTextField.keyboardType = .numberPad
        emailTextField.keyboardType = .emailAddress
        takePictureButton.layer.cornerRadius = 10
        
        //set the firebase user 
        user = FIRAuth.auth()?.currentUser
        
        //set the context for core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        setTheStyle()
        configureDatabase()
        configureStorage()
        
        //look up for existing profile pictures in core data
        getPhotosArray()
        //if there are pictures in core data we fetch it and display it, if there are no pictures in core data but there is a picture in firebase we display it
        placeExistingPhoto()
        
        //cropPictrue to a square 
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameTextField.text = appUser.name
        lastNameTextField.text = appUser.lastName
        emailTextField.text = appUser.email
        phoneNumberTextField.text = appUser.phoneNumber
        
    }

    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)

    }
   
    @IBAction func save(_ sender: Any) {
        
        guard let name = nameTextField.text, name != "" else{
            missingInformation()
            return
        }
        guard let lastName = lastNameTextField.text, lastName != "" else{
            missingInformation()
            return
        }
        guard let email = emailTextField.text, email != "" else{
            missingInformation()
            return
        }
        guard let phoneNumber = phoneNumberTextField.text, phoneNumber != "" else{
            missingInformation()
            return
        }
        
        
        appUser.name = name
        appUser.email = email
        appUser.lastName = lastName
        appUser.phoneNumber = phoneNumber
        appUser.firebaseId = (FIRAuth.auth()?.currentUser?.uid)!
        
        var profileDictionary = [String:String]()
        profileDictionary[Constants.profile.name] = name
        profileDictionary[Constants.profile.email] = email
        profileDictionary[Constants.profile.lastName] = lastName
        profileDictionary[Constants.profile.phoneNumber] = phoneNumber
        profileDictionary[Constants.profile.firebaseId] = (user?.uid)!
        profileDictionary[Constants.profile.imageUrl] = appUser.imageUrl
        profileDictionary[Constants.profile.imageId] = (user?.uid)!
        
        rootReference.child("Users").child("\((user?.uid)!)/Profile").setValue(profileDictionary)
        
        if !uploadingPicture{
            guard appUser.imageUrl != "" else{
                missingProfilePicture()
                return
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    

    @IBAction func takePicture(_ sender: Any) {
        appUser.name = nameTextField.text!
        appUser.email = emailTextField.text!
        appUser.lastName = lastNameTextField.text!
        appUser.phoneNumber = phoneNumberTextField.text!
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)

    }
    func getPhotosArray(){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        let predicate = NSPredicate(format: "imageId = %@", argumentArray: [appUser.imageId])
        fetchRequest.predicate = predicate
        print("we fetch the request")
        context?.performAndWait {
            
            do{
                if let results = try self.context?.fetch(fetchRequest) as? [Profile]{
                    self.photosArray = results
                }
            }catch{
                fatalError("can not get the photos form core data")
            }
        }
        
    }

    func placeExistingPhoto(){
        //set the stylpe for the picture independently of if one exists or not
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        profileImage.clipsToBounds = true
        profileImage.contentMode = .scaleAspectFit
        if photosArray.count == 0{
            if appUser.imageUrl != "" {
                profileImage.loadImage(url: appUser.imageUrl, storageReference: storageReference, saveContext: self.context)
            }
        }else{
            
            let image = UIImage.init(data: photosArray.last!.imageData as! Data, scale: 77)
            DispatchQueue.main.async {
                self.profileImage.image = image
            }
        }
    }
    
    func missingInformation(){
        let alert = UIAlertController(title: NSLocalizedString("Missing Information", comment: "Missing Information: Create Profile"), message: NSLocalizedString("All the entries need to be non-empty", comment: "All the entries need to be non-empty: CreateProfileViewController"), preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func missingProfilePicture(){
        let alert = UIAlertController(title: NSLocalizedString("Take a Picture", comment: "Take a Picture: CreateProfileViewController"), message: NSLocalizedString("Please take a clear picture of your face", comment: "Please take a picture: CreateProfileViewController"), preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true)

    }
    
    func configureStorage(){
        storageReference = FIRStorage.storage().reference()
    }
    
    func configureDatabase(){
        rootReference = FIRDatabase.database().reference()
    }
    
    func setTheStyle(){
        view.backgroundColor = .black//UIColor(colorLiteralRed: 0.2, green: 0.3, blue: 0.4, alpha: 1)
        viewOfTexts.backgroundColor = UIColor(colorLiteralRed: 0.3, green: 0.2, blue: 0.3, alpha: 1)
    }
    
    func textFieldStyle(textField: UITextField){
        
        textStyle(textField: textField)
        
        if textField == nameTextField{
            let topBorder = CALayer()
            let topWidth = CGFloat(2.0)
            topBorder.borderColor = UIColor.white.cgColor
            topBorder.frame = CGRect(x: 0, y: 0, width:  view.frame.size.width, height: topWidth)
            
            topBorder.borderWidth = topWidth
            textField.layer.addSublayer(topBorder)

        }
        
        
        let border = CALayer()
        let width = CGFloat(2.0)
        textField.backgroundColor = .clear
        border.borderColor = UIColor.white.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  view.frame.size.width, height: textField.frame.size.height)
        
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
    
    }
    
    func textStyle(textField: UITextField){
        textField.textColor = .white
        //set the textcolot of a place holder
        func placeHolderColor(string:String){
            let placeHolder = NSLocalizedString(string, comment: string + ": create user")
            textField.attributedPlaceholder = NSAttributedString(string: placeHolder,
                                                                 attributes: [NSForegroundColorAttributeName: UIColor.gray])
        }
        switch textField{
        case nameTextField:
            let placeHolder = NSLocalizedString("Name", comment: "Name: create user")
            placeHolderColor(string: placeHolder)
        case lastNameTextField:
            let placeHolder = NSLocalizedString("Last Name", comment: "Last Name: create user")
            placeHolderColor(string: placeHolder)
        case phoneNumberTextField:
            let placeHolder = NSLocalizedString("Phone Number", comment: "Phone Number: create user")
            placeHolderColor(string: placeHolder)
        case emailTextField:
            let placeHolder = NSLocalizedString("Email", comment: "Email: create user")
            placeHolderColor(string: placeHolder)
        default:
            return
        }
    }
    
    //we use this function to store the photo in Firebase and in Core Data
    func storePhoto(photoData: Data){
        
        uploadingPicture = true
        //check if there is a photo stored in disk, if so erase it
        var profileArray: [Profile] = []
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        let predicate = NSPredicate(format: "imageId = %@", argumentArray: [appUser.imageId])
        fetchRequest.predicate = predicate
        print("we fetch the request")
        context?.performAndWait {
            
            do{
                if let results = try self.context?.fetch(fetchRequest) as? [Profile]{
                   profileArray = results
                }
            }catch{
                fatalError("can not get the photos form core data")
            }
        }
        
        for profile in profileArray{
            context?.perform {
                self.context?.delete(profile)
            }
        }
        
        //build a path
        let imagePath = "ProfilePictures/" + (FIRAuth.auth()?.currentUser!.uid)! +  ".jpg"
        appUser.imageId = (FIRAuth.auth()?.currentUser!.uid)!
        //save the image to core data 
        self.context?.perform{
            let _ = Profile(data: photoData, imageId: self.appUser.imageId, context: self.context!)
        }

        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpeg"
        
        
        //create a childs path for photo data and metaData 
        storageReference!.child(imagePath).put(photoData, metadata: metaData){ (metadata, error) in
            
            if let error = error{
                print("error uploading \(error)")
                return
            }
            
            let imageUrl = "\(self.storageReference.child((metadata?.path!.description)!))"
            
            self.appUser.imageUrl = imageUrl
            //we need to fix this one
            self.rootReference.child("Users/\((FIRAuth.auth()?.currentUser!.uid)!)/Profile/\(Constants.profile.imageUrl)").setValue(imageUrl)
            self.uploadingPicture = false
        }
    }
}

extension CreateProfileViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
               
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
       
    }
}

extension CreateProfileViewController: UIImagePickerControllerDelegate {
    

   func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:Any]) {
        // constant to hold the information about the photo, we save it to 10% of the quality so it downlads fast from 
        //we use edited image becuse we want a square picture
        if let photo = info[UIImagePickerControllerEditedImage] as? UIImage, let photoData = UIImageJPEGRepresentation(photo, 0.1) {
            // call function to upload photo message
            storePhoto(photoData: photoData)
            //set the picture to display imediately after is avaliable 
            self.profileImage.image = photo
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


