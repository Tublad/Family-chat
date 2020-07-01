//
//  User.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 18.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import UIKit

class User: NSObject {
    
    var id: String?
    var email: String?
    var name: String?
    var profileUrl: String?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        id = dictionary["id"] as? String
        email = dictionary["email"] as? String
        name = dictionary["name"] as? String
        profileUrl = dictionary["profileImageUrl"] as? String
    }
    
}
