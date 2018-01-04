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
    @IBOutlet weak var roomNameTxt: UILabel!
    
    func updateViews(room: Room) {
        
        let user_id = room.uid as String
        let room_id  = room.id as String
        let building_id = room.buildingId as String
        roomNameTxt.text = room.roomName as String?
        
        roomImage.clipsToBounds = true
        roomImage.layer.borderWidth = 2
        roomImage.layer.borderColor = UIColor.white.cgColor
        
        let destination = "rooms/\(user_id)/\(building_id)/\(room_id)/"
        
        CloudData.instance.getImages(destination: destination) { (fire_images) in
            if (fire_images.count > 0) {
                let image_key = fire_images[0]
                let reference = "images/rooms/\(user_id)/\(building_id)/\(room_id)/"
                CloudStorage.instance.downloadImage(reference: reference, image_key: image_key, completion: { (image) in
                    self.roomImage.image = image
                })
            } else {
                if (room.imageName != "") {
                    let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(room.imageName as String)
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    self.roomImage.image = image
                }
            }
        }
    }
}
