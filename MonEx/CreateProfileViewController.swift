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

class CreateProfileViewController: UIViewController, UINavigationControllerDelegate {
    
    var storageReference: FIRStorageReference!
    var context: NSManagedObjectContext? = nil
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    
    @IBOutlet weak var takePictureButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        phoneNumberTextField.delegate = self
        takePictureButton.layer.cornerRadius = 10
        
        //set the context for core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        
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
    
    //we use this function to store the photo in Firebase and in Core Data
    func storePhoto(photoData: Data){
        //build a path
        let imagePath = "ProfilePictures/" + (FIRAuth.auth()?.currentUser!.uid)! + ".jpg"
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpeg"
        //TODO: try to mobe the save context photo here 
        
        
        //create a childs path for photo data and metaData 
        storageReference!.child(imagePath).put(photoData, metadata: metaData){ (metadata, error) in
            
            if let error = error{
                print("error uploading \(error)")
                return
            }
            
            let appUser = AppUser.sharedInstance
            appUser.pictureStringURL = "\(self.storageReference.child((metadata?.path!.description)!))"
            self.context?.perform{
                let _ = Profile(data: photoData,imageUrlString:appUser.pictureStringURL, context: self.context!)
            }
            print(self.storageReference.child((metadata?.path!.description)!))
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


