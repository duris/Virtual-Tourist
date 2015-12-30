//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 11/22/15.
//  Copyright © 2015 duris.io. All rights reserved.
//

import UIKit
import CoreData
import MapKit


class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var pin: Pin!
    


    
    /*
    Life Cycle
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the delegates
        fetchedResultsController.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Notification observer for when an image is downloaded
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didLoadImage:", name: "ImageLoadedNotification", object: nil)
        
        //Fetch the Photos from Core Data
        fetchPhotos()
    }
    
    override func viewWillAppear(animated: Bool) {
        //Zoom to location of interest
        prepareMap()
    }
    
    
    
    
    
    /*
    Core Data Convenience
    */
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    
    
    /*
        Map View Helpers
    */
    func centerMapOnLocation(coordinate: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, 8000, 8000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    func prepareMap() {
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        centerMapOnLocation(coordinate)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    
    
    
    
    /*
    Image Loaded Notification
    */
    func didLoadImage(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), {
        print("ImageLoadedNotification")

            self.collectionView.reloadData()
        })

    }

    
    
    
    /*
        Configure Cell
    */
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if photo.isDownloading{
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()
            cell.photoView.image = UIImage(named: "imagePlaceholder")
        } else if photo.image != nil{
            cell.activityIndicator.hidden = true
            cell.activityIndicator.stopAnimating()
            cell.photoView.image = photo.image
        } else if photo.image == nil && !photo.isDownloading{
            photo.isDownloading = true
            var photosToUpdate = [Photo]()
            photosToUpdate.append(photo)
            reloadPhotos(photosToUpdate)
        }
        
    }
    
  
    
    
    /*
        UICollectionView Data
    */
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        dispatch_async(dispatch_get_main_queue(), {

            self.sharedContext.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
            self.saveContext()
        collectionView.reloadData()
        })
    }
    

 
    
    
    
    /*
        Layout the collection view
    */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    
    
    
    
    /*
    Try to fetch the photos from Core Data
    */
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        
        return fetchedResultsController
    }()
    
    func fetchPhotos() {
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
            print("do")
            
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
    }
    
    
    
    
    
    /*
        Fetched Results Controller Delegate
    */
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    
        print("in controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type{
            
        case .Insert:
            print("Insert an item")
            //Photo insterted
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            //Photo deleted
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            //Photo updated
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
                print("photo inserted")
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
                print("photo deleted")
            }
            
            for indexPath in self.updatedIndexPaths {
                print("photo updated")
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

    
    
    @IBAction func newCollection() {
        //Clear current image for each photo
        pin.clearCurrentImages()
        
        //Check the total photo limit to make sure it's updated
        pin.checkForMissingPhotos(collectionView)
        
        //Get new images for each photo
        reloadPhotos(pin.photos)
    }
    
    
    
    
    func reloadPhotos(photos:[Photo]) {
        bottomButton.enabled = false
        Flickr.sharedInstance().getPhotosNearPin(pin) { (photosArray, success, error)  in
            if success{
                for photo in photos {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                        photo.downloadImage(photosArray)
                    }
                }
            } else {
                print("\(error)")
            }

        }
        bottomButton.enabled = true
    }

    
}
