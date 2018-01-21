//
//  EditImageCell.swift
//  Roomly
//
//  Created by Jason Shultz on 1/14/18.
//  Copyright © 2018 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class EditImageCell: UICollectionViewCell {
    
    @IBOutlet weak var editImage: UIImageView!
    
    func updateViews(image: UIImage) {
        editImage.layer.cornerRadius = 5
        editImage.clipsToBounds = true
        editImage.layer.borderWidth = 2
        editImage.layer.borderColor = UIColor.white.cgColor
        
        self.editImage.image = image
    }
    
}
