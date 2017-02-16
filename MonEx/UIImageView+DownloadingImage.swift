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
}
