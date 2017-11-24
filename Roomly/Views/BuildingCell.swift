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
        
        let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(building.imageName as String)
        let image    = UIImage(contentsOfFile: imageURL.path)
        
        buildingImage.image = image
        buildingTitle.text = building.buildingName as! String
    }
    
}
