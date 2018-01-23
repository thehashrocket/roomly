//
//  AddRoomVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/24/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class AddRoomVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource  {
    
    var ref: DatabaseReference!
    var imagesDirectoryPath:String!
    var saved_image = ""
    var selected_building = "" as NSString
    var roomNameText = ""
    var roomDescriptionText = ""
    var images: [UIImage] = []
    
    // Needed for Camera / Photo Gallery
    static let shared = CameraHandler()
    fileprivate var currentVC: UIViewController!
    //MARK: Internal Properties
    var imagePickedBlock: ((UIImage) -> Void)?
    
    // Outlets
    @IBOutlet weak var roomName: UITextField!
    @IBOutlet weak var roomDescription: UITextField!
    @IBOutlet weak var pendingImagesCollection: UICollectionView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        selected_building = DataService.instance.getSelectedBuilding()
        self.ref = Database.database().reference()
        self.ref.keepSynced(true)
        pendingImagesCollection.dataSource = self
        pendingImagesCollection.delegate = self
        
        if !FileManager.default.fileExists(atPath: IMAGE_DIRECTORY_PATH) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: IMAGE_DIRECTORY_PATH), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("AddRoomVC: ")
                print(error)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // Actions
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        performSegue(withIdentifier: "unwindToRoomsVC", sender: self)
    }
    
    @IBAction func submitPicked(_ sender: Any) {
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.ref.child("rooms").child(userID).childByAutoId().key
        
        guard let roomNameText = roomName.text , roomName.text != "" else {
            return
        }
        
        guard let roomDescriptionText = roomDescription.text , roomDescription.text != "" else {
            return
        }
        
        let room = Room(id: key, roomName: roomNameText, roomDescription: roomDescriptionText, imageName: self.saved_image, images: NSDictionary(), buildingId: selected_building as String, uid: userID)
        
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
        performSegue(withIdentifier: "unwindToRoomsVC", sender: self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func addPhotoPressed(_ sender: Any) {
        CameraHandler.shared.showActionSheet(vc: self)
        CameraHandler.shared.imagePickedBlock = { (image) in
            self.images.append(image)
            self.pendingImagesCollection.reloadData()
        }
    }
    
    func showActionSheet(indexPath: Int) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.popoverPresentationController?.sourceView = self.view
        actionSheet.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        actionSheet.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        actionSheet.addAction(UIAlertAction(title: "Delete Photo", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.deletePhoto(indexPath: indexPath)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditImageCell", for: indexPath) as? EditImageCell {
            let image = self.images[indexPath.row]
            cell.updateViews(image: image)
            return cell
        }
        return EditImageCell()
    }
    
    func deletePhoto(indexPath: Int) {
        self.images.remove(at: indexPath)
        self.pendingImagesCollection.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showActionSheet(indexPath: indexPath.row)
    }

}
