//
//  MenuAndDimming.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/16/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import CoreData
import GoogleSignIn
import FirebaseAuth
import Firebase
import AcknowList

class MenuAndDimming: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
     let cellId = "CellId"
     let profileId = "ProfileCell"
     let menuArray = ["(Name)", NSLocalizedString("Log Out", comment: "Log Out"), NSLocalizedString("Acknowledgements", comment: "Acknowledgements")]//(Name) is a placeholder, we do not use this string to populate the menu, but it helps us to get the right count on the array
    var photosArray: [Profile] = []
    var inquiryViewController: InquiryViewController?
    let appUser = AppUser.sharedInstance
    var storageReference: FIRStorageReference!
    var cellName: cellNames = .name
    
    let collectionView: UICollectionView = {
        let layaout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layaout)
        cv.backgroundColor = .white
        return cv
    }()
    
    //we should add payments and history 
    enum cellNames: Int{
        case name = 0
        case logOut = 1
        case acknowledgements = 2
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        configureStorage()
        
        let cellNib = UINib(nibName: profileId, bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: profileId)
        collectionView.register(MenuCell.self, forCellWithReuseIdentifier: cellId)
    }
    
    func configureStorage(){
        storageReference = FIRStorage.storage().reference()
    }

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
   
    func showBlackView(){
        
        if let window = UIApplication.shared.keyWindow{
            self.backgroundColor = .black
            self.alpha = 0
            window.addSubview(self)
            window.addSubview(collectionView)
            
            let width: CGFloat = 0.75*window.frame.width
            collectionView.frame = CGRect(x: -width, y: 0, width: width, height: window.frame.height)
            
            self.frame = window.frame
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBlackView))
            self.addGestureRecognizer(tapGesture)
            
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                self.alpha = 0.5
                self.collectionView.frame.origin.x = 0
            }, completion: nil)
            
        }
        
    }
    
    func dismissBlackView(){
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0
            self.collectionView.frame.origin.x = -self.collectionView.frame.width
        })

    }
    
    func getPhotosArray(){
        
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
        let predicate = NSPredicate(format: "imageId = %@", argumentArray: [appUser.imageId])
        fetchRequest.predicate = predicate
        print("we fetch the request")
        let context = inquiryViewController?.context
        context?.performAndWait {
            
            do{
                if let results = try context?.fetch(fetchRequest) as? [Profile]{
                    self.photosArray = results
                }
            }catch{
                fatalError("can not get the photos form core data")
            }
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return menuArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size:CGSize
        
        if indexPath.item == 0{
            size = CGSize(width: collectionView.frame.width, height: 200)
        }else{
           size = CGSize(width: collectionView.frame.width, height: 50)
        }
        
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0 
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0
            self.collectionView.frame.origin.x = -self.collectionView.frame.width
        }){ completion  in
            self.cellName = cellNames(rawValue: indexPath.row)!
            switch self.cellName{//rawValue: indexPath.item){
            case .name:
            self.inquiryViewController?.presentMakeProfileVC()
            case .logOut:
            self.appUser.clear()
            let firebaseAuth = FIRAuth.auth()
            do {
                try firebaseAuth?.signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            GIDSignIn.sharedInstance().signOut()
            self.inquiryViewController?.dismiss(animated: true, completion: nil)
            case .acknowledgements:
                let path = Bundle.main.path(forResource: "Pods-MonEx-acknowledgements", ofType: "plist")
                let viewController = AcknowListViewController(acknowledgementsPlistPath: path)
                //self.inquiryViewController?.present(viewController, animated:true)
                /*if let navigationController = self.inquiryViewController?.navigationController {
                    navigationController.pushViewController(viewController, animated: true)
                }*/
            }
        }
        
    }
    
   
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: profileId, for:indexPath) as! ProfileCell
            
            //we neet to fetch the photos Array every time, since it may have changed
            
            //if the image was not able to load from core data we check for the image in Firebase
            if !cell.profileImage.existsPhotoInCoreData(imageId: appUser.imageId){
                if appUser.imageUrl != "" {
                    let context = inquiryViewController?.context
                    cell.profileImage.loadImage(url: appUser.imageUrl, storageReference: storageReference, saveContext: context, imageId: appUser.imageId)
                }
                cell.profileImage.image = UIImage(named: "photoPlaceholder")
                
            }
            
            cell.nameLabel.textColor = Constants.color.greenLogoColor
            cell.nameLabel.text = appUser.name == "" ? "Name" : appUser.name
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MenuCell
            let cellText = menuArray[indexPath.item]
            cell.nameLabel.text = cellText
            cell.nameLabel.textColor = Constants.color.greyLogoColor
            return cell
        }
    }
    
    
}
