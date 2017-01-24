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

class MenuAndDimming: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
     let cellId = "CellId"
     let profileId = "ProfileCell"
     let menuArray = ["(Name)","Payment","Transactions", "Log Out"]//(Name) is a placeholder we do not use this string to populate the menu, but it helps us to get the right count on the array
    var photosArray: [Profile] = []
    var inquiryViewController: InquiryViewController?
    
    
    let collectionView: UICollectionView = {
        let layaout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layaout)
        cv.backgroundColor = .white
        return cv
    }()
    
    
    override init(frame: CGRect){
        super.init(frame: frame)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let cellNib = UINib(nibName: profileId, bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: profileId)
        collectionView.register(MenuCell.self, forCellWithReuseIdentifier: cellId)
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
            
            self.inquiryViewController?.presentMakeProfileVC()
        }
        
    }
    
   
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        
        if indexPath.item == 0{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for:indexPath) as! ProfileCell
            
            let appUser = AppUser.sharedInstance
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
            let predicate = NSPredicate(format: "imageUrlString = %@", argumentArray: [appUser.pictureStringURL])
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

            
            if photosArray.count == 0{
                cell.profileImage.image = UIImage(named: "photoPlaceholder")
            }else{
             
                print("the app user picture string " + appUser.pictureStringURL)
                
                let image = UIImage.init(data: photosArray.last!.imageData as! Data, scale: 77)
                DispatchQueue.main.async {
                    cell.profileImage.image = image
                    cell.setNeedsLayout()
                }

            }
            
            return cell
            
        }else{
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MenuCell
            let cellText = menuArray[indexPath.item]
            cell.nameLabel.text = cellText
            return cell
        }
    }
    
    
}
