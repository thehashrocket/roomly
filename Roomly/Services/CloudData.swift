//
//  CloudData.swift
//  Roomly
//
//  Created by Jason Shultz on 12/1/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

class CloudData {
    static let instance = CloudData()
    
    let storage = Storage.storage()
    var ref: DatabaseReference!
    
    func addImagesToRecord(key: String, image: String, user_id: String, destination: String, second_key: String? = nil) {
        self.ref = Database.database().reference()
        let image_key = self.ref.child(destination).child(user_id).child(key).child("images").childByAutoId().key
        let childUpdates = ["\(image_key)": image]
        
        switch destination {
        case "buildings":
            self.ref.child(destination).child(user_id).child(key).child("images").updateChildValues(childUpdates)
        default:
            self.ref.child(destination).child(user_id).child(second_key!).child(key).child("images").updateChildValues(childUpdates)
        }
        
        
    }
    
    func getImages(destination: String, completion: @escaping ([String]) -> Void) {
        var return_images = [String]()
        self.ref = Database.database().reference()
        self.ref.child(destination).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let images = value?["images"] as? NSDictionary
            
            if ((images) != nil) {
                for (key,value) in images! {
                    return_images.append(value as! String)
                }
                completion(return_images)
            }

        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
}
