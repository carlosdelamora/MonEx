//
//  OtherOffer+CoreDataProperties.swift
//  MonEx
//
//  Created by Carlos De la mora on 3/21/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation
import CoreData


extension OtherOffer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OtherOffer> {
        return NSFetchRequest<OtherOffer>(entityName: "OtherOffer");
    }

    @NSManaged public var firebaseIdOther: String?
    @NSManaged public var name: String?
    @NSManaged public var imageUrlOfOther: String?
    @NSManaged public var bidId: String?

}
