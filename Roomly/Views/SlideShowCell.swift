//
//  SlideShowCell.swift
//  Roomly
//
//  Created by Jason Shultz on 12/16/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class SlideShowCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func updateView(image: UIImage) {
        self.imageView.image = image
    }
    
    
}
