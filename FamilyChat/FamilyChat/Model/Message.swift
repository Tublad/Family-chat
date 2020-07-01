//
//  Message.swift
//  FamilyChat
//
//  Created by Евгений Шварцкопф on 23.06.2020.
//  Copyright © 2020 Евгений Шварцкопф. All rights reserved.
//

import Foundation
import Firebase

class Message: NSObject {
    
    var toId: String?
    var timestamp: NSNumber?
    var fromId: String?
    var text: String?
    
    var imageUrl: String?
    
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    
    var videoUrl: String?
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        toId = dictionary["toId"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        text = dictionary["text"] as? String
        
        imageUrl = dictionary["imageUrl"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
}
