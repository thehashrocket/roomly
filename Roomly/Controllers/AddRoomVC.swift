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

class AddRoomVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    var ref: DatabaseReference!
    var imagesDirectoryPath:String!
    var saved_image = ""
    var selected_building = "" as NSString
    var roomNameText = ""
    var roomDescriptionText = ""
    
    // Outlets
    @IBOutlet weak var roomName: UITextField!
    @IBOutlet weak var roomDescription: UITextField!
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        selected_building = DataService.instance.getSelectedBuilding()
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
    
    @IBAction func openCameraButton(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func submitPicked(_ sender: Any) {
        spinner.startAnimating()
        spinner.isHidden = false
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.ref.child("rooms").child(userID).childByAutoId().key
        
        guard let roomNameText = roomName.text , roomName.text != "" else {
            return
        }
        
        guard let roomDescriptionText = roomDescription.text , roomDescription.text != "" else {
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
        spinner.stopAnimating()
        spinner.isHidden = true
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func cancelPicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.saved_image = saveImageToDocumentDirectory(pickedImage!)
        imagePicked.image = pickedImage
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        
    }
    
    func saveImageToDocumentDirectory(_ chosenImage: UIImage) -> String {
        
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let date = formatter.string(from: NSDate() as Date).replacingOccurrences(of: " ", with: "_")
        
        let filename = date.appending(".jpg")
        let filepath = IMAGE_DIRECTORY_PATH + "/".appending(filename)
        let url = NSURL.fileURL(withPath: filepath)
        do {
            try UIImageJPEGRepresentation(chosenImage, 1.0)?.write(to: url, options: .atomic)
            return String.init("\(filename)")
            
        } catch {
            print(error)
            print("file cant not be save at path \(filepath), with error : \(error)");
            return filepath
        }
    }


}
