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

class EditBuildingVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Variables
    var ref: DatabaseReference!
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
        
        let building = Building(id: key, buildingName: name, street: street, city: city, state: state, zip: zip, uid: userID, imageName: self.saved_image)
        
        let post = [
            "buildingName" : building.buildingName,
            "street" : building.street,
            "city" : building.city,
            "state" : building.state,
            "zip" : building.zip,
            "uid" : building.uid,
            "id" : building.id,
            "imageName": building.imageName
        ]
        
        let childUpdates = ["/buildings/\(userID)/\(key)": post]
        self.ref.updateChildValues(childUpdates)
        spinner.stopAnimating()
        spinner.hidesWhenStopped = true
        spinner.isHidden = true
        self.dismiss(animated: true, completion: nil)
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
    
    @IBAction func deletePressed(_ sender: Any) {
        let userID = Auth.auth().currentUser?.uid
        self.ref = Database.database().reference()
        self.ref.child("buildings").child(userID!).child(self.selected_building as String).removeValue()
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let vc = storyboard.instantiateViewController(withIdentifier: "BuildingVC") as! BuildingVC    // VC1 refers to destinationVC source file and "VC1" refers to destinationVC Storyboard ID
//        self.present(vc, animated: true, completion: nil)
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
                    
                    let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(value?["imageName"] as! String)
                    let image    = UIImage(contentsOfFile: imageURL.path)
                    
                    self.imagePicked.image = image
                    
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
