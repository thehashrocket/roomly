//
//  BuildingCell.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class BuildingCell: UITableViewCell {
    
    @IBOutlet weak var buildingImage: UIImageView!
    @IBOutlet weak var buildingTitle: UILabel!
    
    func updateViews(building: Building) {
        
        let user_id = building.uid as String
        let building_id = building.id as String
        
        let destination = "buildings/\(user_id)/\(building_id)/"
        
        CloudData.instance.getImages(destination: destination) { (fire_images) in
            if (fire_images.count > 0) {
                let image_key = fire_images[0]
                let reference = "images/buildings/\(user_id)/\(building_id)/"
                CloudStorage.instance.downloadImage(reference: reference, image_key: image_key, completion: { (image) in
                    self.buildingImage.image = image
                })
            } else {
                if (building.imageName != "") {
                    let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(building.imageName as String)
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    self.buildingImage.image = image
                }
            }
        }
        
        buildingTitle.text = building.buildingName as! String
    }
    
}
