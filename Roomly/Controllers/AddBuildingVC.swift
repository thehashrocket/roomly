//
//  AddBuildingVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/23/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import ImagePicker
import Lightbox

class AddBuildingVC: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource,
UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Variables
    let storage = Storage.storage()
    var ref: DatabaseReference!
    var images: [UIImage] = []
    var imagesDirectoryPath:String!
    var saved_image = ""
    var worldArray = [(city: String, country: String, state: String, geoId: String)]()
    var citiesArray = [(String)]()
    var statesArray = [(String)]()
    var countriesArray = [(String)]()
    
    // Needed for Camera / Photo Gallery
    static let shared = CameraHandler()
    fileprivate var currentVC: UIViewController!
    //MARK: Internal Properties
    var imagePickedBlock: ((UIImage) -> Void)?

    
    // Outlets
    @IBOutlet weak var buildingNameTxt: UITextField!
    @IBOutlet weak var streetTxt: UITextField!
    @IBOutlet weak var cityTxt: UITextField!
    @IBOutlet weak var stateTxt: UITextField!
    @IBOutlet weak var countryTxt: UITextField!
    @IBOutlet weak var zipTxt: UITextField!
    @IBOutlet weak var pendingImagesCollection: UICollectionView!
    
    
    @IBOutlet weak var imgProfile: UIImageView!
    var imagePicker = UIImagePickerController()
    
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
        
        pendingImagesCollection.dataSource = self
        pendingImagesCollection.delegate = self
        
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
        
        self.ref = Database.database().reference()

        if !FileManager.default.fileExists(atPath: IMAGE_DIRECTORY_PATH) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: IMAGE_DIRECTORY_PATH), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("AddBuildingVC: ")
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
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Actions
    
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func dismissPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        performSegue(withIdentifier: "unwindtoBuildingVC", sender: self)
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.ref.child("buildings").child(userID).childByAutoId().key
        
        guard let name = buildingNameTxt.text , buildingNameTxt.text != "" else {
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
        
        var files = [String: NSString]()
        let building = Building(id: key, buildingName: name, street: street, city: city, state: state, country: country, zip: zip, uid: userID, imageName: self.saved_image, images: files as NSDictionary)
        
        let post = [
            "buildingName" : building.buildingName,
            "street" : building.street,
            "city" : building.city,
            "state" : building.state,
            "country" : building.country,
            "zip" : building.zip,
            "uid" : building.uid,
            "id" : building.id,
            "imageName": building.imageName,
            "images": files,
            ] as [String : Any]
        
        let childUpdates = ["/buildings/\(userID)/\(key)": post]
        self.ref.updateChildValues(childUpdates)
        
        self.images.forEach { (image) in
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "buildings")
        }
        performSegue(withIdentifier: "unwindtoBuildingVC", sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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
    
    func readBundle(file:String) -> String
    {
        var res = ""
        if let asset = NSDataAsset(name: file) ,
            let string = String(data:asset.data, encoding: String.Encoding.utf8){
            res = string
        }
        return res
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

}
