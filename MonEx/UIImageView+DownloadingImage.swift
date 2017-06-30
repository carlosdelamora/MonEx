//
//  UIImageView+DownloadingImage.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/4/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import Firebase
import UIKit
import CoreData


extension UIImageView{
    
    //load image to the app from Firebase and save it to CoreData 
    //TODO: Check what storageReference is need it here?
    func loadImage(url:String, storageReference:FIRStorageReference, saveContext:NSManagedObjectContext?, imageId : String ){
        
        
        
        DispatchQueue.main.async {
            
            //we check if we have an activity indicator with the tag 200, if we do not we create one
            let activityIndicator = self.viewWithTag(200) as? UIActivityIndicatorView
            if activityIndicator == nil{
                let activity = UIActivityIndicatorView()
                activity.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(activity)
                self.centerXAnchor.constraint(equalTo: activity.centerXAnchor).isActive = true
                self.centerYAnchor.constraint(equalTo: activity.centerYAnchor).isActive = true
                activity.startAnimating()
                activity.color = Constants.color.greenLogoColor
                activity.tag = 200
            }else{
                activityIndicator?.startAnimating()
            }
        }
    
        FIRStorage.storage().reference(forURL: url).data(withMaxSize: INT64_MAX){ [weak self] data,error in
            guard (error == nil) else{
                print("error downloading \(error!)")
                return
            }
            //display image
            let imageData = UIImage.init(data: data!, scale: 50)
            
            //save to context if need it 
            if let context = saveContext{
                context.perform{
                    let _ = Profile(data: data!, imageId: imageId, context: context)
                }
            }
            
            DispatchQueue.main.async {
                if let strongSelf = self{
                    let activity = strongSelf.viewWithTag(200) as? UIActivityIndicatorView
                    strongSelf.layer.cornerRadius = strongSelf.frame.width/2
                    strongSelf.clipsToBounds = true
                    strongSelf.image = imageData
                    activity?.stopAnimating()
                }
            }
        }
    }
    
    
    func existsPhotoInCoreData(imageId: String)->Bool{
        var success = false
        //set the context for core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        let context = stack?.context
        var photosArray = [Profile]()
       
        func getPhotosArray() -> [Profile]{
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
            let predicate = NSPredicate(format: "imageId = %@", argumentArray: [imageId])
            fetchRequest.predicate = predicate
            print("we fetch the request")
            context?.performAndWait {
                
                do{
                    if let results = try context?.fetch(fetchRequest) as? [Profile]{
                        photosArray = results
                    }
                }catch{
                    fatalError("can not get the photos form core data")
                }
            }
            return photosArray
        }
        
        photosArray = getPhotosArray()
        if photosArray.count > 0 {
            success = true
            let image = UIImage.init(data: photosArray.last!.imageData as! Data, scale: 77)
            DispatchQueue.main.async {
                self.layer.cornerRadius = self.frame.width/2
                self.clipsToBounds = true
                self.image = image
            }

        }
        return success
    }
}
