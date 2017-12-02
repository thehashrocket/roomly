//
//  EditBuildingVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/24/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import ImagePicker
import Lightbox

class EditBuildingVC: UIViewController, ImagePickerDelegate {
    
    // Variables
    var ref: DatabaseReference!
    var images: [UIImage] = []
    var imagesDirectoryPath:String!
    var saved_image = ""
    var selected_building = "" as NSString
    
    // Outlets
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var buildingNAme: UITextField!
    @IBOutlet weak var streetTxt: UITextField!
    @IBOutlet weak var cityTxt: UITextField!
    @IBOutlet weak var stateTxt: UITextField!
    @IBOutlet weak var zipTxt: UITextField!
    
    // Actions
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func closePressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        spinner.startAnimating()
        spinner.isHidden = false
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.selected_building as String
        
        guard let name = buildingNAme.text , buildingNAme.text != "" else {
            return
        }
        guard let street = streetTxt.text , streetTxt.text != "" else {
            return
        }
        guard let city = cityTxt.text , cityTxt.text != "" else {
            return
        }
        guard let state = stateTxt.text , stateTxt.text != "" else {
            return
        }
        guard let zip = zipTxt.text , zipTxt.text != "" else {
            return
        }
        let files = NSDictionary()
        
        let building = Building(id: key, buildingName: name, street: street, city: city, state: state, zip: zip, uid: userID, imageName: self.saved_image, images: files)
        
        let post = [
            "buildingName" : building.buildingName,
            "street" : building.street,
            "city" : building.city,
            "state" : building.state,
            "zip" : building.zip,
            "uid" : building.uid,
            "id" : building.id,
            "imageName": building.imageName,
            "files": files
            ] as [String : Any]
        
        let childUpdates = ["/buildings/\(userID)/\(key)": post]
        self.ref.updateChildValues(childUpdates)
        
        self.images.forEach { (image) in
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "buildings")
        }
        
        spinner.stopAnimating()
        spinner.hidesWhenStopped = true
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
        self.ref.child("buildings").child(userID!).child(self.selected_building as String).removeValue()

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
        spinner.stopAnimating()
        spinner.isHidden = true
        
        selected_building = DataService.instance.getSelectedBuilding()

        self.ref = Database.database().reference()
        // Do any additional setup after loading the view.
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                
                let userID = Auth.auth().currentUser?.uid
                self.ref.child("buildings").child(userID!).child(self.selected_building as String).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    
                    self.buildingNAme.text = value?["buildingName"] as! String
                    self.streetTxt.text = value?["street"] as! String
                    self.cityTxt.text = value?["city"] as! String
                    self.stateTxt.text = value?["state"] as! String
                    self.zipTxt.text = value?["zip"] as! String
                    self.saved_image = value?["imageName"] as! String
                    
                    let building_id = value?["id"] as! String
                    let user_id = userID as! String
                    let destination = "buildings/\(user_id)/\(building_id)/"
                    
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
