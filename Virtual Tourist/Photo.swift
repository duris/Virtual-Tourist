//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 11/22/15.
//  Copyright © 2015 duris.io. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    

    
    @NSManaged var imagePath: String
    @NSManaged var pin: Pin?
        
    var isDownloading = false
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        imagePath = dictionary["imagePath"] as! String
    }
    
 
    func deleteImage(path: String){
        FlickrClient.Caches.imageCache.removeImage(path)
    }
    
    func downloadImage(pin: Pin) {
        FlickrClient.sharedInstance().downloadPhotoForPin(pin)
    }
    
    
    var image: UIImage? {
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: imagePath)
        }
    }
}
