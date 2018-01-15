//
//  DeleteImageCell.swift
//  Roomly
//
//  Created by Jason Shultz on 1/14/18.
//  Copyright © 2018 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class DeleteImageCell: UICollectionViewCell {
    
    @IBOutlet weak var editImage: UIImageView!
    
    func updateViews(image: (key: Any, value: Any), image_category: String, category_key_1: String, user_id: String, category_key_2: String) {
        editImage.layer.cornerRadius = 5
        editImage.clipsToBounds = true
        editImage.layer.borderWidth = 2
        editImage.layer.borderColor = UIColor.white.cgColor
        var image_destination = ""
        
        if image_category == "buildings" {
            image_destination = "\(image_category)/\(user_id)/\(category_key_1)/"
        } else {
            image_destination = "\(image_category)/\(category_key_1)/\(user_id)/\(category_key_2)"
            
        }
        
        
        CloudStorage.instance.downloadImage(reference: image_destination, image_key: image.value as! String, completion: { (image) in
            self.editImage.image = image
        })
    }
    
}
