//
//  RoomCell.swift
//  Roomly
//
//  Created by Jason Shultz on 10/9/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class RoomCell: UICollectionViewCell {
    
    @IBOutlet weak var roomImage: UIImageView!
    
    func updateViews(room: Room) {
        let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(room.imageName as String)
        let image    = UIImage(contentsOfFile: imageURL.path)
        
        roomImage.image = image
    }
    
}
