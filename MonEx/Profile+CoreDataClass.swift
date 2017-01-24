//
//  Profile+CoreDataClass.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/23/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import CoreData


public class Profile: NSManagedObject {
    
    convenience init(data: Data, imageId:String, context: NSManagedObjectContext){
        if let entity = NSEntityDescription.entity(forEntityName: "Profile", in: context){
            self.init(entity: entity, insertInto: context)
            self.imageData = data as NSData
            self.imageId = imageId
        }else{
            fatalError("there was an error with initalization")
        }
    }

}
