//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 11/26/15.
//  Copyright © 2015 duris.io. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class FlickrClient : NSObject {
    
    
    /* Shared session */
    var session: NSURLSession
    
    var images = [UIImage]()
    
    /* Flickr API Constants */
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "10c066e8d3e9dbaf544ccc679c18b177"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0

    //Photo Download Limit
    static let PHOTO_LIMIT = 21

    
    /* Initialize the session */
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    

    func searchPhotosNearPin(pin: Pin, completionHandler: (imageData: NSData?, success: Bool, errorString: String!) -> Void)  {

            //Loading
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(pin.latitude, longitude: pin.longitude),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
//        getImageFromFlickrBySearch(methodArguments){ (imageData, success, errorString) in
//            if success {
//                completionHandler(imageData:imageData, success: true, errorString: nil)
//            }
//        }
        
        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: 1) { (imageData, success, errorString) in
            if success {
                completionHandler(imageData: imageData!, success: true, errorString: nil)
            }
        }

    }
    
    

    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }



    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
//    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject], completionHandler: (imageData: NSData, success: Bool, errorString: String!) -> Void) {
//        
//        let session = NSURLSession.sharedSession()
//        let urlString = BASE_URL + escapedParameters(methodArguments)
//        let url = NSURL(string: urlString)!
//        let request = NSURLRequest(URL: url)
//        
//        print("starting first request")
//        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
//            if let error = downloadError {
//                print("Could not complete the request \(error)")
//            } else {
//                
//                let parsingError: NSError? = nil
//                let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary
//                
//                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
//                    
//                    if let totalPages = photosDictionary["pages"] as? Int {
//                        
//                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
//                        let pageLimit = min(totalPages, 40)
//                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
//                        
//                        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage) { (imageData, success, errorString) in
//                            if success {
//                                completionHandler(imageData: imageData!, success: true, errorString: nil)
//                            }
//                        }
//                        
//                    } else {
//                        print("Cant find key 'pages' in \(photosDictionary)")
//                    }
//                } else {
//                    print("Cant find key 'photos' in \(parsedResult)")
//                }
//            }
//        }
//        
//        task.resume()
//    }

    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (imageData: NSData?, success: Bool, errorString: String!) -> Void) {
        
        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        print("starting second request")
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Could not complete the request \(error)")
            } else {
                let parsingError: NSError? = nil
                let parsedResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                        print(totalPhotosVal)
                    }
                    
                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                                let imageUrlString = photoDictionary["url_m"] as? String
                                let imageURL = NSURL(string: imageUrlString!)
                                print(imageUrlString)
                                
                                if let imageData = NSData(contentsOfURL: imageURL!) {
                                    dispatch_async(dispatch_get_main_queue(), {
                                        
                                        
                                        completionHandler(imageData: imageData, success: true, errorString: nil)
                                        
                                        
                                    })
                                    
                                } else {
                                    print("Image does not exist at \(imageURL)")
                                    completionHandler(imageData: NSData(), success: false, errorString: "Image does not exist at \(imageURL)")
                                }
                            

                            
                            
                            
                        } else {
                            print("Cant find key 'photo' in \(photosDictionary)")
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            print("No Photos Found")
                        })
                    }
                } else {
                    print("Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func downloadPhotoForPin(pin: Pin){
        let uuid = NSUUID().UUIDString
        let photoDictionary: [String : AnyObject] = [
            "imagePath": "image_\(uuid)"
        ]
        let photo = Photo(dictionary: photoDictionary, context: self.sharedContext)
        photo.pin = pin
        saveContext()
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

    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    /* Shared Instance */
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}


