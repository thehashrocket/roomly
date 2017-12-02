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
import ImagePicker
import Lightbox

class EditRoomVC: UIViewController, ImagePickerDelegate {
    
    // Variables
    var ref: DatabaseReference!
    var imagesDirectoryPath:String!
    var saved_image = ""
    var selected_building = "" as NSString
    var selected_room = "" as NSString
    var roomNameText = ""
    var roomDescriptionText = ""
    var images: [UIImage] = []
    
    
    // Outlets
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var roomNameTxt: UITextField!
    @IBOutlet weak var roomDescriptionTxt: UITextField!
    @IBOutlet weak var imagePicked: UIImageView!
    
    
    // Actions
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func closePicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitPicked(_ sender: Any) {
        spinner.startAnimating()
        spinner.isHidden = false
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.selected_room as String
        
        guard let roomNameText = roomNameTxt.text , roomNameTxt.text != "" else {
            return
        }
        
        guard let roomDescriptionText = roomDescriptionTxt.text , roomDescriptionTxt.text != "" else {
            return
        }
        
        let room = Room(id: key, roomName: roomNameText, roomDescription: roomDescriptionText, imageName: self.saved_image, buildingId: selected_building as String, uid: userID)
        
        let post = [
            "roomName" : room.roomName,
            "roomDescription" : room.roomDescription,
            "imageName": room.imageName,
            "buildingId" : room.buildingId,
            "uid" : room.uid,
            "id" : room.id,
            ]
        
        let childUpdates = ["/rooms/\(userID)/\(selected_building)/\(key)": post]
        self.ref.updateChildValues(childUpdates)
        
        self.images.forEach { (image) in
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "rooms", second_key: room.buildingId as! String)
        }
        
        spinner.stopAnimating()
        spinner.isHidden = true
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func openCameraButton(_ sender: Any) {
        var config = Configuration()
        config.doneButtonTitle = "Finish"
        config.noImagesTitle = "Sorry! There are no images here!"
        config.recordLocation = false
        config.allowVideoSelection = true
        
        let imagePicker = ImagePickerController(configuration: config)
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        let userID = Auth.auth().currentUser?.uid
        self.ref = Database.database().reference()
        self.ref.child("rooms").child(userID!).child(self.selected_building as String).child(self.selected_room as String).removeValue()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let VC1 = storyboard.instantiateViewController(withIdentifier: "BuildingVC") as! BuildingVC
        let navController = UINavigationController(rootViewController: VC1) // Creating a navigation controller with VC1 at the root of the navigation stack.

        self.present(navController, animated:true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selected_building = DataService.instance.getSelectedBuilding()
        selected_room = DataService.instance.getSelectedRoom()
        spinner.isHidden = true
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
                    let room_id = value?["id"] as! String
                    
                    let building_id = value?["id"] as! String
                    let user_id = userID as! String
                    let destination = "rooms/\(user_id)/\(building_id)/\(room_id)/"
                    
                    CloudStorage.instance.loadTopImage(destination: destination, saved_image: self.saved_image, completion: { (image) in
                        self.imagePicked.image = image
                    })
                    
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
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        guard images.count > 0 else { return }
        
        let lightboxImages = images.map {
            return LightboxImage(image: $0)
        }
        
        let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
        imagePicker.present(lightbox, animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        self.images = images
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }

}
