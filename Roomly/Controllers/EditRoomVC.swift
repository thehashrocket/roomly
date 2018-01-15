//
//  EditRoomVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/25/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class EditRoomVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Variables
    var ref: DatabaseReference!
    var imageDictionary = NSDictionary()
    var imagesDirectoryPath:String!
    var saved_image = ""
    var selected_building = "" as NSString
    var selected_room = "" as NSString
    var roomNameText = ""
    var roomDescriptionText = ""
    var images: [UIImage] = []
    
    // Outlets

    @IBOutlet weak var roomNameTxt: UITextField!
    @IBOutlet weak var roomDescriptionTxt: UITextField!
    @IBOutlet weak var editImagesCollection: UICollectionView!
    
    
    // Actions
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func cancelPicked(_ sender: Any) {
        performSegue(withIdentifier: "unwindToItemsVC", sender: self)
    }
    
    @IBAction func submitPicked(_ sender: Any) {
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.selected_room as String
        
        guard let roomNameText = roomNameTxt.text , roomNameTxt.text != "" else {
            return
        }
        
        guard let roomDescriptionText = roomDescriptionTxt.text , roomDescriptionTxt.text != "" else {
            return
        }
        
        let room = Room(id: key, roomName: roomNameText, roomDescription: roomDescriptionText, imageName: self.saved_image, images: self.imageDictionary, buildingId: selected_building as String, uid: userID)
        
        let post = [
            "roomName" : room.roomName,
            "roomDescription" : room.roomDescription,
            "imageName": room.imageName,
            "images": room.images,
            "buildingId" : room.buildingId,
            "uid" : room.uid,
            "id" : room.id,
            ] as [String : Any]
        
        let childUpdates = ["/rooms/\(userID)/\(selected_building)/\(key)": post]
        self.ref.updateChildValues(childUpdates)
        
        self.images.forEach { (image) in
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "rooms", second_key: room.buildingId as! String)
        }
        
        performSegue(withIdentifier: "unwindToItemsVC", sender: self)
        
    }
    
    @IBAction func openCameraButton(_ sender: Any) {
        CameraHandler.shared.showActionSheet(vc: self)
        CameraHandler.shared.imagePickedBlock = { (image) in
            let key = self.selected_room as String
            guard let userID = Auth.auth().currentUser?.uid else { return }
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "rooms")
            self.editImagesCollection.reloadData()
        }
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        let userID = Auth.auth().currentUser?.uid
        self.ref = Database.database().reference()
        
        let roomsRef = self.ref.child("rooms").child(userID!)
        roomsRef.keepSynced(true)
        roomsRef.child(self.selected_building as String).child(self.selected_room as String).removeValue { (error, _) in
            if (error == nil) {
                print("delete Room")
                self.performSegue(withIdentifier: "unwindToRoomsVC", sender: self)
            } else {
                print("deleting room: ")
                print(error!)
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editImagesCollection.dataSource = self
        editImagesCollection.delegate = self
        selected_building = DataService.instance.getSelectedBuilding()
        selected_room = DataService.instance.getSelectedRoom()

        self.ref = Database.database().reference()
        
        // Do any additional setup after loading the view.
        
        if !FileManager.default.fileExists(atPath: IMAGE_DIRECTORY_PATH) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: IMAGE_DIRECTORY_PATH), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                let userID = Auth.auth().currentUser?.uid
                self.ref.child("rooms").child(userID!).child(self.selected_building as String).child(self.selected_room as String).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    
                    self.roomNameTxt.text = value?["roomName"] as? String
                    self.roomDescriptionTxt.text = value?["roomDescription"] as? String
                    self.saved_image = value?["imageName"] as! String
                    if ((value?["images"]) != nil) {
                        self.imageDictionary = (value?["images"] as? NSDictionary)!
                        self.editImagesCollection.reloadData()
                    } else {
                        self.imageDictionary = NSDictionary()
                        self.editImagesCollection.reloadData()
                    }
                    
                    
                    let room_id = value?["id"] as! String
                    
                    let building_id = value?["id"] as! String
                    let user_id = userID as! String
                    let destination = "rooms/\(user_id)/\(building_id)/\(room_id)/"
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
                
            } else {
                // TODO: Segue to WelcomeVC here.
                print("No user is signed in.")
            }
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func showActionSheet(indexPath: Int) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Delete Photo", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.deletePhoto(indexPath: indexPath)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageDictionary.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DeleteImageCell", for: indexPath) as? DeleteImageCell {
            let userID = Auth.auth().currentUser?.uid
            
            let image = Array(self.imageDictionary)[indexPath.row]
            cell.updateViews(image: image, image_category: "rooms", category_key_1: self.selected_building as! String, user_id: userID!, category_key_2: self.selected_room as! String)
            return cell
        }
        return EditImageCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showActionSheet(indexPath: indexPath.row)
    }
    
    func deletePhoto(indexPath: Int) {
        self.images.remove(at: indexPath)
        self.editImagesCollection.reloadData()
    }

}
