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
            image_destination = "\(image_category)/\(user_id)/\(category_key_1)/\(category_key_2)"
        }
        
        CloudData.instance.getImages(destination: image_destination) { (fire_images) in
            if (fire_images.count > 0) {
                CloudStorage.instance.downloadImage(reference: image_destination, image_key: image.value as! String, completion: { (found_image, error) in
                    if let error = error {
                        print("i am in the error")
                        
                        CloudStorage.instance.downloadImage(reference: image_destination, image_key: image.value as! String, completion: { (found_image, error) in
                            if let error = error {
                                print("i am in the error again.")
                            } else {
                                print(found_image)
                                self.editImage.image = found_image
                            }
                        })
                        
                    } else {
                        print(image)
                        self.editImage.image = found_image
                    }
                })
            } else {
                if (image.value as! String != "") {
                    let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(image.value as! String)
                    let temp_image    = UIImage(contentsOfFile: imageURL.path)
                    self.editImage.image = temp_image
                }
            }
        }
        
    }
    
}
