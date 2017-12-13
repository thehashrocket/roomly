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
        self.ref.keepSynced(true)
        let image_key = self.ref.child(destination).child(user_id).child(key).child("images").childByAutoId().key
        let childUpdates = ["\(image_key)": image]
        
        switch destination {
        case "buildings":
            self.ref.child(destination).child(user_id).child(key).child("images").updateChildValues(childUpdates)
        default:
            self.ref.child(destination).child(user_id).child(second_key!).child(key).child("images").updateChildValues(childUpdates)
        }
    }
    
    func getAllBuildings(userID: String, completion: @escaping ([Building]) -> Void) {
        var buildings = [Building]()
        
        self.ref.child("buildings").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in

            snapshot.children.forEach({ (child) in
                let snap = child as! DataSnapshot
                _ = snap.key
                let value = snap.value
                
                let dataChange = value as! [String: AnyObject]
                
                let id = dataChange["id"] as? String
                let buildingName = dataChange["buildingName"] as? String
                let street = dataChange["street"] as? String
                let city = dataChange["city"] as? String
                let state = dataChange["state"] as? String
                let country = dataChange["country"] as? String
                let zip = dataChange["zip"] as? String
                let uid = dataChange["uid"] as? String
                
                let building = Building(id: id!, buildingName: buildingName!, street: street!, city: city!, state: state!, country: country!, zip: zip!, uid: uid!, imageName: "", images: [:])
                
                buildings.append(building)
                
            })
            completion(buildings)
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getAllRooms(userID: String, buildingId: String, completion: @escaping ([Room]) -> Void) {
        var rooms = [Room]()

        self.ref.child("rooms").child(userID).child(buildingId as String).observeSingleEvent(of: .value, with: { (snapshot) in
            
            snapshot.children.forEach({ (child) in
                let snap = child as! DataSnapshot
                _ = snap.key
                let value = snap.value
                
                let dataChange = value as! [String: AnyObject]
                
                let id = dataChange["id"] as? String
                let roomName = dataChange["roomName"] as? String
                let roomDescription = dataChange["roomDescription"] as? String
                let buildingId = dataChange["buildingId"] as? String
                let uid = dataChange["uid"] as? String
                
                let room = Room(id: id!, roomName: roomName!, roomDescription: roomDescription!, imageName: "", buildingId: buildingId!, uid: uid!)
                
                rooms.append(room)
            })
            completion(rooms)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func getImages(destination: String, completion: @escaping ([String]) -> Void) {
        var return_images = [String]()
        self.ref = Database.database().reference()
        self.ref.keepSynced(true)
        self.ref.child(destination).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let images = value?["images"] as? NSDictionary
            
            if ((images) != nil) {
                for (_,value) in images! {
                    return_images.append(value as! String)
                }
                completion(return_images)
            }

        }) { (error) in
            print("Get Images: ")
            print(error.localizedDescription)
        }
    }
    
}
