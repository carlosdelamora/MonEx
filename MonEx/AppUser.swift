//
//  AppUser.swift
//  MonEx
//
//  Created by Carlos De la mora on 1/18/17.
//  Copyright © 2017 carlosdelamora. All rights reserved.
//

import Foundation

class AppUser{
    
    static let sharedInstance = AppUser()
    
    var name: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var FirebaseId: String = ""
    var pictureStringURL: String = ""
    var imageId: String = ""
    
    private init(){
        
    }
    
   
    func clear(){
        self.name = ""
        self.lastName = ""
        self.email = ""
        self.phoneNumber = ""
        self.FirebaseId = ""
        self.pictureStringURL = ""
        self.imageId = ""
    }
    
}
