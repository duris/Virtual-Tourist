//
//  MapLocation.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 12/5/15.
//  Copyright © 2015 duris.io. All rights reserved.
//


import CoreData
import UIKit
import MapKit


class MapLocation: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var latitudeDelta: Double
    @NSManaged var longitudeDelta: Double
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("MapLocation", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        latitude = dictionary["latitude"] as! Double
        longitude = dictionary["longitude"] as! Double
        latitude = dictionary["latitudeDelta"] as! Double
        longitude = dictionary["longitudeDelta"] as! Double
    }    
}