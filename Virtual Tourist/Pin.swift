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
    
    func deletePhotos() {
        for photo in self.photos {
            Flickr.Caches.imageCache.removeImage(photo.imagePath)
            sharedContext.deleteObject(photo)
        }
        saveContext()
    }
  
    
    func clearCurrentImages(){
        for photo in self.photos {
            Flickr.Caches.imageCache.removeImage(photo.imagePath)
            photo.isDownloading = true
            photo.image = nil
        }
    }
    
    func checkForMissingPhotos(collectionView:UICollectionView){
        if self.photos.count < Flickr.PHOTO_LIMIT {
            for _ in 1...(Flickr.PHOTO_LIMIT - self.photos.count) {
                let uuid = NSUUID().UUIDString
                let dictionary: [String : AnyObject] = [
                    "imagePath": "image_\(uuid)",
                    "imageUrlString": ""
                ]
                let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                photo.pin = self
                photo.isDownloading = true
            }
            self.saveContext()
        }
        collectionView.reloadData()
    }
    
    
    func generatePhotos(){
        for _ in 1...Flickr.PHOTO_LIMIT {
            let uuid = NSUUID().UUIDString
            let dictionary: [String : AnyObject] = [
                "imagePath": "image_\(uuid)",
                "imageUrlString": ""
            ]
            let photo = Photo(dictionary: dictionary, context: self.sharedContext)
            photo.pin = self
            photo.isDownloading = true
        }
        saveContext()
    }
    
    func reloadPhotos(photos:[Photo]) {
        Flickr.sharedInstance().getPhotosNearPin(self) { (photosArray, success, error)  in
            for photo in photos {
                dispatch_async(dispatch_get_main_queue(), {
                    photo.downloadImage(photosArray)
                })
            }
        }
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }

        
}



