//
//  OtherOffer+CoreDataClass.swift
//  MonEx
//
//  Created by Carlos De la mora on 3/21/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import CoreData


public class OtherOffer: NSManagedObject {
    
    convenience init( bidId: String, firebaseIdOther: String, imageUrlOfOther:String, name: String,context: NSManagedObjectContext){
        
        if let entity = NSEntityDescription.entity(forEntityName: "OtherOffer", in: context){
            self.init(entity: entity, insertInto: context)
            self.firebaseIdOther = firebaseIdOther
            self.imageUrlOfOther = imageUrlOfOther
            
        }else{
            fatalError("there was an error with initalization")
        }
    }
}
