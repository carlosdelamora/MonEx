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

extension UIImageView{
    
    func loadImage(url:String, storageReference:FIRStorageReference){
        FIRStorage.storage().reference(forURL: url).data(withMaxSize: INT64_MAX){ [weak self] data,error in
            guard (error == nil) else{
                print("error downloading \(error!)")
                return
            }
            //display image
            let imageData = UIImage.init(data: data!, scale: 50)
            DispatchQueue.main.async {
                if let strongSelf = self{
                    strongSelf.image = imageData
                }
            }
        }
    }
}
