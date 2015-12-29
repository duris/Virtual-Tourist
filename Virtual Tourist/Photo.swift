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
    @NSManaged var imageUrlString: String
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
        imageUrlString = dictionary["imageUrlString"] as! String
    }
    
 
    func deleteImage(path: String){
        Flickr.Caches.imageCache.removeImage(path)
    }
    
    func downloadImage(photosArray:[[String: AnyObject]]) {
        self.isDownloading = true
        let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
        let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
        let imageUrlString = photoDictionary["url_m"] as? String
        self.imageUrlString = imageUrlString!
        if self.imageUrlString != "" {
            if let imageURL = NSURL(string: self.imageUrlString) {
                if let imageData = NSData(contentsOfURL: imageURL) {
                    let image = UIImage(data: imageData)
                    self.image = image!
                    Flickr.Caches.imageCache.storeImage(image, withIdentifier: self.imagePath)
                    self.isDownloading = false
                    print("photo loaded")
                    NSNotificationCenter.defaultCenter().postNotificationName("ImageLoadedNotification", object: self)
                    
                    self.saveContext()
                }
            } else {
                print("no photo URL")
            }
        }
    }
    
    
    
    
    var image: UIImage? {
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(image, withIdentifier: imagePath)
        }
    }
}
