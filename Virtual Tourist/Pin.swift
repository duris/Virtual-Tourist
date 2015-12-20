//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 11/22/15.
//  Copyright © 2015 duris.io. All rights reserved.
//

import CoreData
import UIKit
import MapKit


class Pin: NSManagedObject, MKAnnotation {
    
    @NSManaged var id: String!
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    var title : String?
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(latitude as Double, longitude as Double)
        }
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        id = dictionary["id"] as! String
        latitude = dictionary["latitude"] as! Double
        longitude = dictionary["longitude"] as! Double
    }
    
    func deletePhotos(photos:[Photo]) {
        for photo in photos {
            print("deleting photo")
            FlickrClient.Caches.imageCache.removeImage(photo.imagePath)
            sharedContext.deleteObject(photo)
        }
    }
    
    func updatePhotos(pin: Pin) {
        for photo in pin.photos {
            if photo.image == nil && photo.isDownloading == false{
                photo.isDownloading = true
                FlickrClient.sharedInstance().searchPhotosNearPin(pin) { (imageData, success, errorString) in
                    if success {
                        if let data = imageData {
                            let image = UIImage(data: data)
                            print(image!)
                            photo.image = image!
                            FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: photo.imagePath)
                            photo.isDownloading = false
                            
                            NSNotificationCenter.defaultCenter().postNotificationName("ImageLoadedNotification", object: self)
                        }
                        
                        self.saveContext()
                        
                    } else {
                        print("nothing")
                    }
                }
            }
        }
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }

        
}



