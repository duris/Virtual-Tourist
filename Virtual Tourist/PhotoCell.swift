//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Ross Duris on 11/26/15.
//  Copyright © 2015 duris.io. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var photo: UIImageView {
        set {
            self.photoView = newValue
        }
        
        get {
            return self.photoView
        }
    }
}
