//
//  UIImageView+DownloadingImage.swift
//  MonEx
//
//  Created by Carlos De la mora on 2/4/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import FirebaseStorageUI
import UIKit
import CoreData

extension UIImageView{
    
    
    func loadImage(url:String, storageReference:FIRStorageReference, saveContext:NSManagedObjectContext? ){
        
    
        
        self.layer.cornerRadius = self.frame.width/2
        self.clipsToBounds = true 
        FIRStorage.storage().reference(forURL: url).data(withMaxSize: INT64_MAX){ [weak self] data,error in
            guard (error == nil) else{
                print("error downloading \(error!)")
                return
            }
            //display image
            let imageData = UIImage.init(data: data!, scale: 50)
            
            //save to context if need it 
            if let context = saveContext{
                let appUser = AppUser.sharedInstance
                context.perform{
                    let _ = Profile(data: data!, imageId: appUser.imageId, context: context)
                }
            }
            
            DispatchQueue.main.async {
                if let strongSelf = self{
                    strongSelf.image = imageData
                }
            }
        }
    }
    
    
    func loadFromCoreData(imageId: String)->Bool{
        let success = false
        //set the context for core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        let context = stack?.context
        var photosArray = [Profile]()
        
        func getPhotosArray(){
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
            
        }

        
            
        
        return success
    }
}
