//
//  ItemCell.swift
//  Roomly
//
//  Created by Jason Shultz on 11/25/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class ItemCell: UICollectionViewCell {
    
    @IBOutlet weak var itemImage: UIImageView!
    
    func updateViews(item: Item) {
        if (item.imageName != "") {
            let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(item.imageName as String)
            let image    = UIImage(contentsOfFile: imageURL.path)
            itemImage.image = image
        }
    }
    
}
