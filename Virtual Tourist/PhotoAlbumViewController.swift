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
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var pin: Pin!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didDownloadImage:", name: "ImageLoadedNotification", object: nil)
        
        
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

        if pin.photos.isEmpty {
            
        } else {
            print(pin.photos.count)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        centerMapOnLocation(coordinate)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func centerMapOnLocation(coordinate: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, 8000, 8000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func didDownloadImage(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
        }
    }

    // MARK: - Configure Cell
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if photo.isDownloading && photo.image == nil{
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()
            cell.photoView.image = UIImage(named: "imagePlaceholder")
        } else {
            cell.activityIndicator.hidden = true
            cell.activityIndicator.stopAnimating()
            cell.photoView.image = photo.image
        }
    }
    
    // MARK: - UICollectionView
    
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

        self.sharedContext.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)

        collectionView.reloadData()
        saveContext()
        configureCell(cell, atIndexPath: indexPath)
   
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        
        return fetchedResultsController
    }()
    
    // Layout the collection view
    
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
    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Color object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type{
            
        case .Insert:
            print("Insert an item")
            // Here we are noting that a new Color instance has been added to Core Data. We remember its index path
            // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
            // the index path that we want in this case
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            // Here we are noting that a Color instance has been deleted from Core Data. We keep remember its index path
            // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
            // value that we want in this case.
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            // We don't expect Color instances to change after they are created. But Core Data would
            // notify us of changes if any occured. This can be useful if you want to respond to changes
            // that come about after data is downloaded. For example, when an images is downloaded from
            // Flickr in the Virtual Tourist app
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
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
                print("dingle insert")
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
                print("dingle delete")
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

    
    /* 
    NEEDS FINISHED
    */
    
//    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        sharedContext.deleteObject(pin.photos[indexPath.row])
//        collectionView.reloadData()
//    }
 
    
    @IBAction func newCollection() {
      deletePhotos(pin.photos)
    }
    
    func deletePhotos(photos:[Photo]) {
        for photo in photos {
            print("deleting image")
            FlickrClient.Caches.imageCache.removeImage(photo.imagePath)
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
        collectionView.reloadData()
    }

    
}
