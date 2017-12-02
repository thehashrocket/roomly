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
        if (item.id != "") {
            
            let user_id = item.uid! as String
            let room_id  = item.roomId! as String
            let item_id = item.id! as String
            
            let destination = "items/\(user_id)/\(room_id)/\(item_id)/"
            
            CloudData.instance.getImages(destination: destination) { (fire_images) in
                if (fire_images.count > 0) {
                    let image_key = fire_images[0]
                    let reference = "images/items/\(user_id)/\(room_id)/\(item_id)/\(image_key)"
                    CloudStorage.instance.downloadImage(reference: reference, completion: { (image) in
                        self.itemImage.image = image
                    })
                } else {
                    if (item.imageName != "") {
                        let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(item.imageName as String)
                        let image    = UIImage(contentsOfFile: imageURL.path)
                        self.itemImage.image = image
                    }
                }
            }
        }
    }
    
}
