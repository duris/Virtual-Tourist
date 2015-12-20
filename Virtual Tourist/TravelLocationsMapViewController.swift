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
    var longPress = UILongPressGestureRecognizer()
    var coordinate = CLLocationCoordinate2D(latitude: 0.00, longitude: 0.00)
    var locations = [Location]()
    var activePin : Pin!
    var editMode = false

    
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
        longPress = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longPress.delegate = self
        longPress.numberOfTapsRequired = 0
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        
        //Fetch CoreData
        do {
            try fetchedResultsController.performFetch()
        } catch {
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

    
    func fetchSelectedPin(view: MKAnnotationView) -> Pin {
        
        
        let fetchSelectedPin: NSFetchedResultsController = {
            let fetchRequest = NSFetchRequest(entityName: "Pin")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
            let uuid = (((view.annotation?.title)!)!)
            let uuidPredicate = NSPredicate(format: "uuid = %@", "\(uuid)")
            fetchRequest.predicate = uuidPredicate
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                managedObjectContext: self.sharedContext,
                sectionNameKeyPath: nil,
                cacheName: nil)
            
            return fetchedResultsController
        }()
        
        do {
            try fetchSelectedPin.performFetch()
        } catch {
            print("Error fetching pin")
        }
        
        
        return (fetchSelectedPin.fetchedObjects?.first as? Pin)!
    }

    
    
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
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
      
    }

    func getPins(){
        for annotation in self.mapView.annotations{
            self.mapView.removeAnnotation(annotation)
        }
        for item in fetchedResultsController.fetchedObjects! {
            let pin = item as! Pin
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = pin.latitude
            annotation.coordinate.longitude = pin.longitude
            annotation.title = pin.uuid
            
            mapView.addAnnotation(annotation)
        }
    }
    
    func getLocation() -> [Location] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Location]
        } catch _ {
            return [Location]()
        }
    }
    
//    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        let dictionary: [String : AnyObject] = [
//            "latitude": mapView.region.center.latitude,
//            "longitude": mapView.region.center.longitude,
//            "latitudeDelta": mapView.region.span.latitudeDelta,
//            "longitudeDelta": mapView.region.span.longitudeDelta
//        ]
//        
//        print(mapView.region.span.longitudeDelta)
//        
//        
//        
//        let location = Location(dictionary: dictionary, context:  sharedContext)
//        locations.removeAll()
//        locations.append(location)
//        print(locations.count)
//        saveContext()
//    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {

    }
    
    func addAnnotation(gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            let uuid = NSUUID().UUIDString
            print(uuid)
            annotation.title = uuid as String

            let dictionary: [String : AnyObject] = [
                "uuid": uuid,
                "latitude": annotation.coordinate.latitude,
                "longitude": annotation.coordinate.longitude
            ]
            
            let pin = Pin(dictionary: dictionary, context: sharedContext)
            
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.Ending {
            let pin = fetchSelectedPin(view)
            pin.latitude = (view.annotation?.coordinate.latitude)!
            pin.longitude = (view.annotation?.coordinate.longitude)!

            saveContext()
        }
    }


    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
    }
    
//    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
//        
//        
// 
//        if editMode{
//            let pin = fetchSelectedPin(view)
//            mapView.removeAnnotation(view.annotation!)
//            sharedContext.deleteObject(pin)
//        } else {
//            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
//            print(view.annotation)
//            let pin = fetchSelectedPin(view)
//            vc.pin = pin
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
//    }

    
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
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                annotationView!.canShowCallout = false
                annotationView!.animatesDrop = true
                annotationView!.draggable = true
                annotationView!.pinTintColor = UIColor.redColor()
            
                
                // Configure singleTap Gesture
                let singleTap = UITapGestureRecognizer(target: self, action: "annotationTap:")
                singleTap.delegate = self
                singleTap.numberOfTapsRequired = 1
                annotationView!.addGestureRecognizer(singleTap)
                
            }
            else {
                print("error")
                annotationView!.annotation = annotation
            }

            
            return annotationView
    }
    
    func annotationTap(sender: UITapGestureRecognizer) {
        let view = sender.view as! MKPinAnnotationView
        if editMode{
            let pin = fetchSelectedPin(view)
            mapView.removeAnnotation(view.annotation!)
            sharedContext.deleteObject(pin)
        } else {
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
            let pin = fetchSelectedPin(view)
            vc.pin = pin
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func annotationHold() {
        print("annotation held")
    }



}
