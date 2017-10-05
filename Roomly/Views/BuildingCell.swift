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
        buildingImage.image = UIImage(named: building.imageName)
        buildingTitle.text = building.title
    }
    
}
