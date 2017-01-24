//
//  Profile+CoreDataProperties.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/24/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var imageId: String?

}
