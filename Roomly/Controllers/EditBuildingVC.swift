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

class EditBuildingVC: UIViewController, ImagePickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // Variables
    var ref: DatabaseReference!
    var images: [UIImage] = []
    var imageDictionary = NSDictionary()
    var imagesDirectoryPath:String!
    var saved_image = ""
    var selected_building = "" as NSString
    var worldArray = [(city: String, country: String, state: String, geoId: String)]()
    var citiesArray = [(String)]()
    var statesArray = [(String)]()
    var countriesArray = [(String)]()
    
    // Outlets
    @IBOutlet weak var buildingNAme: UITextField!
    @IBOutlet weak var streetTxt: UITextField!
    @IBOutlet weak var cityTxt: UITextField!
    @IBOutlet weak var countryTxt: UITextField!
    @IBOutlet weak var stateTxt: UITextField!
    @IBOutlet weak var zipTxt: UITextField!
    
    // Actions
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        performSegue(withIdentifier: "unwindToRoomsVC", sender: self)
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        
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
        guard let country = countryTxt.text , countryTxt.text != "" else {
            return
        }
        guard let zip = zipTxt.text , zipTxt.text != "" else {
            return
        }
        let files = NSDictionary()
        
        let building = Building(id: key, buildingName: name, street: street, city: city, state: state, country: country, zip: zip, uid: userID, imageName: self.saved_image, images: self.imageDictionary)
        
        let post = [
            "buildingName" : building.buildingName,
            "street" : building.street,
            "city" : building.city,
            "country" : building.country,
            "state" : building.state,
            "zip" : building.zip,
            "uid" : building.uid,
            "id" : building.id,
            "imageName": building.imageName,
            "images": building.images
            ] as [String : Any]
        
        let childUpdates = ["/buildings/\(userID)/\(key)": post]
        self.ref.updateChildValues(childUpdates)
        
        self.images.forEach { (image) in
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "buildings")
        }
        
        performSegue(withIdentifier: "unwindToRoomsVC", sender: self)
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

        performSegue(withIdentifier: "unwindToBuildingVC", sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cityPicker = UIPickerView()
        let countryPicker = UIPickerView()
        let statePicker = UIPickerView()
        cityTxt.inputView = cityPicker
        stateTxt.inputView = statePicker
        countryTxt.inputView = countryPicker
        cityPicker.delegate = self
        countryPicker.delegate = self
        statePicker.delegate = self
        
        let textFile = readBundle(file: "world-cities")
        let lineArray = textFile.components(separatedBy: "\n") // Separating Lines
        for eachLA in lineArray {
            let temp = eachLA.components(separatedBy: ",")
            if (temp[0] != "") {
                worldArray.append((temp[0], temp[1], temp[2], temp[3]))
            }
        }
        
        // Begin Filtering Countries
        let countries = worldArray.map({$0.1})
        let sortedCountries = countries.sorted(by: <)
        countriesArray = DataService.instance.uniqueElementsFrom(array: sortedCountries)
        
        // Begin Filtering States
        let states = worldArray.map({$0.2})
        let sortedStates = states.sorted(by: <)
        statesArray = DataService.instance.uniqueElementsFrom(array: sortedStates)
        // End Filtering States
        
        // Filter Cities //
        citiesArray = DataService.instance.filterWorldDataByState(data: worldArray, state: "")
        
        selected_building = DataService.instance.getSelectedBuilding()

        self.ref = Database.database().reference()

        // Do any additional setup after loading the view.
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                
                let userID = Auth.auth().currentUser?.uid
                let buildingRef = self.ref.child("buildings").child(userID!)
                buildingRef.keepSynced(true)
                
                buildingRef.child(self.selected_building as String).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    
                    let value = snapshot.value as? NSDictionary
                    
                    self.buildingNAme.text = value?["buildingName"] as! String
                    self.streetTxt.text = value?["street"] as! String
                    self.cityTxt.text = value?["city"] as! String
                    self.countryTxt.text = value?["country"] as! String
                    self.stateTxt.text = value?["state"] as! String
                    self.zipTxt.text = value?["zip"] as! String
                    self.saved_image = value?["imageName"] as! String
                    if ((value?["images"]) != nil) {
                        self.imageDictionary = (value?["images"] as? NSDictionary)!
                    }
                    
                    
                    let building_id = value?["id"] as! String
                    let user_id = userID as! String
                    let destination = "buildings/\(user_id)/\(building_id)/"
                    
//                    CloudStorage.instance.loadTopImage(destination: destination, saved_image: self.saved_image, completion: { (image) in
//                        self.imagePicked.image = image
//                    })
                    
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if cityTxt.isFirstResponder{
            return citiesArray.count
        } else if stateTxt.isFirstResponder{
            return statesArray.count
        } else {
            return countriesArray.count
        }
    }
    
    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if cityTxt.isFirstResponder{
            return citiesArray[row]
        } else if stateTxt.isFirstResponder{
            return statesArray[row]
        } else {
            return countriesArray[row]
        }
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if stateTxt.isFirstResponder{
            self.citiesArray = DataService.instance.filterWorldDataByState(data: worldArray, state: statesArray[row])
            stateTxt.text = statesArray[row]
        } else if cityTxt.isFirstResponder {
            cityTxt.text = citiesArray[row]
        } else {
            self.statesArray = DataService.instance.filterWorldDataByCountry(data: worldArray, country: countriesArray[row])
            countryTxt.text = countriesArray[row]
        }
    }
    
    func readBundle(file:String) -> String
    {
        var res = ""
        if let asset = NSDataAsset(name: file) ,
            let string = String(data:asset.data, encoding: String.Encoding.utf8){
            res = string
        }
        return res
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
