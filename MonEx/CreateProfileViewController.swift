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
        takePictureButton.layer.cornerRadius = 10
        
        
        //set the context for core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        setTheStyle()
        configureDatabase()
        configureStorage()
        
    }

    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: Any) {
    }
    

    @IBAction func takePicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        present(picker, animated: true, completion: nil)

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
        
        //check if there is a photo stored in disk, if so erase it
        let appUser = AppUser.sharedInstance
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
        //let now = Date()
        //let timeStamp = "\(now.timeIntervalSince1970)
        let imagePath = "ProfilePictures/" + (FIRAuth.auth()?.currentUser!.uid)! +  ".jpg"
        appUser.imageId = (FIRAuth.auth()?.currentUser!.uid)!
        //save the image to core data 
        self.context?.perform{
            let _ = Profile(data: photoData, imageId: appUser.imageId, context: self.context!)
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
            
            appUser.pictureStringURL = imageUrl
            self.rootReference.child("\((FIRAuth.auth()?.currentUser!.uid)!)/\(Constants.Profile.imageUrl)").setValue(imageUrl)
            
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
        // constant to hold the information about the photo
        if let photo = info[UIImagePickerControllerOriginalImage] as? UIImage, let photoData = UIImageJPEGRepresentation(photo, 0.8) {
            // call function to upload photo message
            storePhoto(photoData: photoData)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


