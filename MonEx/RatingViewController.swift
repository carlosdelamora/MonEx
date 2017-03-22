//
//  RatingViewController.swift
//  MonEx
//
//  Created by Carlos De la mora on 3/21/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import UIKit
import Cosmos
import FirebaseStorage

class RatingViewController: UIViewController {
    
    var storageReference: FIRStorageReference!
    var acceptViewController: AcceptOfferViewController?
    var imageUrlOfTheOther: String?
    var firebaseIdOftheOther: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureStorage()
        //get the imageURL form the user defaults
        guard let dataImage = UserDefaults.standard.value(forKey: (acceptViewController?.offer?.bidId)!) as? [String] else{
            return
        }
        
        imageUrlOfTheOther = dataImage[0]
        firebaseIdOftheOther = dataImage[1]
        
        imageView.loadImage(url: imageUrlOfTheOther!, storageReference: storageReference, saveContext: nil, imageId: firebaseIdOftheOther!)
        label.text = NSLocalizedString("Give a rating", comment: "Give a rating: rating view controller")
    }

    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var cosmosView: CosmosView!
    
    @IBAction func submitButton(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: {
                self.acceptViewController?.dismissAcceptViewController(goToMyBids: false)
            })
        }
        
    }
    
    func configureStorage(){
        storageReference = FIRStorage.storage().reference()
    }

}
