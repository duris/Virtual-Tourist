//
//  Location.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 11/23/15.
//  Copyright © 2015 duris.io. All rights reserved.
//

import CoreData

class Location : NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var latitudeDelta: Double
    @NSManaged var longitudeDelta: Double
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Location", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        latitude = dictionary["latitude"] as! Double
        longitude = dictionary["longitude"] as! Double
        latitudeDelta = dictionary["latitudeDelta"] as! Double
        longitudeDelta = dictionary["longitudeDelta"] as! Double
    }
}
