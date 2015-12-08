//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 11/22/15.
//  Copyright © 2015 duris.io. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var editView: UIView!
    var editMode = false
    var dragPin: MKPointAnnotation!
    var mapLocation: MapLocation!
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set mapView delegate
        mapView.delegate = self
        
        // Set fetchedResultsController delegate
        fetchedResultsController.delegate = self
        
        editButton.title = "Edit"
        editView.hidden = true
        

        
        // Configure LongPress Gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longPress.delegate = self
        longPress.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(longPress)
        
        //Fetch CoreData
        do {
            try fetchedResultsController.performFetch()
        } catch {
        }
        
        fetchMapRegion() { (found, mapLocation) in
            if found {
                self.setMapRegion(mapLocation!)
                self.mapLocation = mapLocation
            }else {
                self.creatMapRegin()
            }
        }

        getPins()
    }
    
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()

    
    
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        //LOADING INDICATOR
    }

    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                print("insert")
                fetchedResultsChangeInsert(anObject as! Pin)
                print(fetchedResultsController.fetchedObjects?.count)
                
            case .Delete:
                fetchedResultsChangeDelete(anObject as! Pin)
                print("delete")
                
            case .Update:
                fetchedResultsChangeUpdate(anObject as! Pin)
                print("update")
                
            default:
                return
            }
    }
    
    func fetchedResultsChangeInsert(pin: Pin) {
     
        print("Pin Inserted")
        saveContext()
    }
    
    func fetchedResultsChangeDelete(pin: Pin) {
        print("Pin Deleted")
        saveContext()
    }
    
    func fetchedResultsChangeUpdate(pin: Pin) {
        print("Pin Updated")
        saveContext()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
      
    }

    func getPins(){
        for annotation in self.mapView.annotations{
            self.mapView.removeAnnotation(annotation)
        }
        for item in fetchedResultsController.fetchedObjects! {
            let pin = item as! Pin
            mapView.addAnnotation(pin)
        }
    }
    

    func addAnnotation(gestureRecognizer:UIGestureRecognizer){

            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        
            if dragPin != nil {
                dragPin.coordinate = newCoordinates
            }
        
        
            if gestureRecognizer.state == UIGestureRecognizerState.Began {
                dragPin = MKPointAnnotation()
                dragPin.coordinate = newCoordinates
                
                self.mapView.addAnnotation(dragPin)
                
            }else if gestureRecognizer.state == UIGestureRecognizerState.Ended {
                let touchPoint = gestureRecognizer.locationInView(mapView)
                let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
                print(coordinate)
                
                let uuid = NSUUID().UUIDString

                let dictionary: [String : AnyObject] = [
                    "id": uuid,
                    "latitude": newCoordinates.latitude,
                    "longitude": newCoordinates.longitude
                ]
                let pin = Pin(dictionary: dictionary, context: sharedContext)
                self.mapView.addAnnotation(pin)
                self.mapView.removeAnnotation(dragPin)
                dragPin = nil
                for _ in 1...FlickrClient.PHOTO_LIMIT {
                    FlickrClient.sharedInstance().downloadPhotoForPin(pin)
                }
                
            }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
//        if photo.downloadStatus == .Loaded {
//            photo.delete()
//        }
    }

    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        fetchMapRegion() { (found, mapLocation) in
            if found {
                self.updateMapRegion(mapLocation!)
            }
        }
    }


    
    func fetchMapRegion(completionHandler:(found: Bool, mapLocation: MapLocation?) -> Void) {
        let mapLocationFetch = NSFetchRequest(entityName: "MapLocation")
        
        do {
            let mapLocation = try self.sharedContext.executeFetchRequest(mapLocationFetch) as! [MapLocation]
            
            if mapLocation.isEmpty {
                completionHandler(found: false, mapLocation: nil)
            } else {
                completionHandler(found: true, mapLocation: mapLocation.first)
            }
            
        } catch {
            fatalError("Failed to fetch map location: \(error)")
        }

    }
    
    func creatMapRegin(){
        let region = self.mapView.region
        let dictionary = [
            "latitude": region.center.latitude,
            "longitude": region.center.longitude,
            "latitudeDelta":   region.span.latitudeDelta,
            "longitudeDelta":   region.span.longitudeDelta
        ]
        let location = MapLocation(dictionary: dictionary, context: sharedContext)
        self.mapLocation = location
        saveContext()
    }
    
    func updateMapRegion(mapLocation: MapLocation) {
        let region = self.mapView.region
        mapLocation.latitude = region.center.latitude
        mapLocation.longitude = region.center.longitude
        mapLocation.latitudeDelta = region.span.latitudeDelta
        mapLocation.longitudeDelta = region.span.longitudeDelta
        saveContext()
    }
    
    func setMapRegion(mapLocation: MapLocation){
        let region = MKCoordinateRegionMake(
            CLLocationCoordinate2DMake(
                mapLocation.latitude as Double,
                mapLocation.longitude as Double
            ),
            MKCoordinateSpanMake(
                mapLocation.latitudeDelta as Double,
                mapLocation.longitudeDelta as Double
            )
        )
        self.mapView.setRegion(region, animated: true)
    }
    

    @IBAction func didPressEdit(){
        if editMode{
            editButton.title = "Edit"
            editMode = false
            editView.hidden = true
        } else {
            editButton.title = "Done"
            editMode = true
            editView.hidden = false
        }
    }


    func mapView(mapView: MKMapView,
        viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
            
            if annotation is MKUserLocation {
                //return nil so map view draws "blue dot" for standard user location
                return nil
            }
            
            let reuseId = "pin"
            
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
            if annotation is Pin{
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                annotationView!.canShowCallout = false
                annotationView!.animatesDrop = false
                annotationView!.draggable = true
                annotationView!.pinTintColor = UIColor.redColor()
            }else {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                annotationView!.canShowCallout = false
                annotationView!.animatesDrop = true
                annotationView!.draggable = true
                annotationView!.pinTintColor = UIColor.purpleColor()

            }
            return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

        if editMode{
            let pin = view.annotation as! Pin
            //mapView.removeAnnotation(view.annotation!)
            //deletePhotos(pin.photos)
            sharedContext.deleteObject(pin)
            saveContext()
        } else {
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
            let pin = view.annotation as! Pin
            updatePhotos(pin)
            for photo in pin.photos {
                print(photo.isDownloading)
            }
            vc.pin = pin
            self.navigationController?.pushViewController(vc, animated: true)
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
    
    func deletePhotos(photos:[Photo]) {
        for photo in photos {
            print("deleting photo")
            FlickrClient.Caches.imageCache.removeImage(photo.imagePath)
            sharedContext.deleteObject(photo)
        }
    }


}
