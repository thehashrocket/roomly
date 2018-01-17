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
    @IBOutlet weak var itemNameTxt: UILabel!
    
    func updateViews(item: Item) {
        if (item.id != "") {
            
            let user_id = item.uid! as String
            let room_id  = item.roomId! as String
            let item_id = item.id! as String
            itemNameTxt.text = item.itemName as String?
            
            itemImage.layer.cornerRadius = 5
            itemImage.clipsToBounds = true
            itemImage.layer.borderWidth = 2
            itemImage.layer.borderColor = UIColor.white.cgColor
            
            let destination = "items/\(user_id)/\(room_id)/\(item_id)/"
            
            CloudData.instance.getImages(destination: destination) { (fire_images) in
                if (fire_images.count > 0) {
                    let image_key = fire_images[0]
                    let reference = "images/items/\(user_id)/\(room_id)/\(item_id)/"
                    CloudStorage.instance.downloadImage(reference: reference, image_key: image_key, completion: { (image, error) in
                        if let error = error {
                            print(error)
                        } else {
                            self.itemImage.image = image
                        }
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
