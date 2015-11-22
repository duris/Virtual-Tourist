//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 11/22/15.
//  Copyright © 2015 duris.io. All rights reserved.
//

import CoreData

class Pin: NSManagedObject {
    
    @NSManaged var id: NSNumber
    @NSManaged var latitude: String
    @NSManaged var longitude: String
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        id = dictionary["id"] as! Int
        latitude = dictionary["latitude"] as! String
        longitude = dictionary["longitude"] as! String
    }
    
}



