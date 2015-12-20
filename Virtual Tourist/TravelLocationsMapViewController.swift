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
    
    
    
    
    /*
        Life Cycle
    */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set mapView delegate
        mapView.delegate = self
        
        //Set fetchedPinsController delegate
        fetchedPinsController.delegate = self
        
        //Prepare Edit Button
        editButton.title = "Edit"
        editView.hidden = true
        
        // Configure LongPress Gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longPress.delegate = self
        longPress.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(longPress)
        
        //Fetch Map Region
        fetchMapRegion()
        
        //Fetch Pins
        fetchPins()
    }
    
    
    
    
    /*
        Core Data Convenience
    */
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }


    
    
    /*
        Fetched Pins Controller
    */
    lazy var fetchedPinsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
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
                print(fetchedPinsController.fetchedObjects?.count)
                
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

    func fetchPins(){
        do {
            try fetchedPinsController.performFetch()
        } catch {
        }
        for annotation in self.mapView.annotations{
            self.mapView.removeAnnotation(annotation)
        }
        for item in fetchedPinsController.fetchedObjects! {
            let pin = item as! Pin
            mapView.addAnnotation(pin)
        }
    }
    
    
    

    /*
        Add Annotation
    */
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
                pin.title = "hey"
                self.mapView.addAnnotation(pin)
                self.mapView.removeAnnotation(dragPin)
                dragPin = nil
                for _ in 1...FlickrClient.PHOTO_LIMIT {
                    FlickrClient.sharedInstance().downloadPhotoForPin(pin)
                }
                
            }
    }
    
    
    

    /*
        Configure Edit Mode
    */
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
    
    


    /*
        MapView Delegate Methods
    */
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
        mapView.deselectAnnotation(view.annotation, animated: false)
        if editMode{
            let pin = view.annotation as! Pin
            mapView.removeAnnotation(view.annotation!)
            pin.deletePhotos(pin.photos)
            sharedContext.deleteObject(pin)
            saveContext()
        } else {
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
            let pin = view.annotation as! Pin
            pin.updatePhotos(pin)
            for photo in pin.photos {
                print(photo.isDownloading)
            }
            vc.pin = pin
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        fetchMapRegionController() { (found, mapLocation) in
            if found {
                self.updateMapRegion(mapLocation!)
            }
        }
    }
    
    
    
   
    /*
        MapRegion Helpers
    */
    func fetchMapRegionController(completionHandler:(found: Bool, mapLocation: MapLocation?) -> Void) {
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
    
    func fetchMapRegion(){
        fetchMapRegionController() { (found, mapLocation) in
            if found {
                self.setMapRegion(mapLocation!)
                self.mapLocation = mapLocation
            }else {
                self.creatMapRegin()
            }
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

}
