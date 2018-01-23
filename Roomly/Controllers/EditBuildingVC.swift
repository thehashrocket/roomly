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


class EditBuildingVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Variables
    var ref: DatabaseReference!
    var images: [UIImage] = []
    var imageDictionary = NSDictionary()
    var imagesDirectoryPath:String!
    var image_name = ""
    var saved_image = ""
    var selected_building = "" as NSString
    var worldArray = [(city: String, country: String, state: String, geoId: String)]()
    var citiesArray = [(String)]()
    var statesArray = [(String)]()
    var countriesArray = [(String)]()
    var building_id = String()
    
    // Outlets
    @IBOutlet weak var buildingNAme: UITextField!
    @IBOutlet weak var streetTxt: UITextField!
    @IBOutlet weak var cityTxt: UITextField!
    @IBOutlet weak var countryTxt: UITextField!
    @IBOutlet weak var stateTxt: UITextField!
    @IBOutlet weak var zipTxt: UITextField!
    @IBOutlet weak var editImagesCollection: UICollectionView!
    
    
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
        
        performSegue(withIdentifier: "unwindToRoomsVC", sender: self)
    }
    
    @IBAction func openCameraButton(_ sender: Any) {
        CameraHandler.shared.showActionSheet(vc: self)
        CameraHandler.shared.imagePickedBlock = { (image) in
            let key = self.selected_building as String
            guard let userID = Auth.auth().currentUser?.uid else { return }
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "buildings")
        }
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
        
        editImagesCollection.dataSource = self
        editImagesCollection.delegate = self
        
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
                
                buildingRef.child(self.selected_building as String).observe(DataEventType.value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    
                    self.buildingNAme.text = value?["buildingName"] as? String
                    self.streetTxt.text = value?["street"] as? String
                    self.cityTxt.text = value?["city"] as? String
                    self.countryTxt.text = value?["country"] as? String
                    self.stateTxt.text = value?["state"] as? String
                    self.zipTxt.text = value?["zip"] as? String
                    if ((value?["imageName"]) != nil) {
                        self.saved_image = value!["imageName"] as! String
                    }
                    
                    if ((value?["images"]) != nil) {
                        self.imageDictionary = (value?["images"] as? NSDictionary)!
                        self.editImagesCollection.reloadData()
                    }
                    if ((value?["id"]) != nil) {
                        self.building_id = value?["id"] as! String
                    }
                    
                    let user_id = userID as! String
                    let destination = "buildings/\(user_id)/\(self.building_id)/"

                }, withCancel: { (error) in
                    print(error.localizedDescription)
                })
                
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
        return self.imageDictionary.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DeleteImageCell", for: indexPath) as? DeleteImageCell {
            let userID = Auth.auth().currentUser?.uid
            
            let image = Array(self.imageDictionary)[indexPath.row]
            cell.updateViews(image: image, image_category: "buildings", category_key_1: self.building_id, user_id: userID!, category_key_2: "")
            return cell
        }
        return EditImageCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showActionSheet(indexPath: indexPath.row)
    }
    
    func deletePhoto(indexPath: Int) {
        let image:(key: Any, value: Any) = Array(self.imageDictionary)[indexPath]
        print(image.value)
        let userID = Auth.auth().currentUser?.uid
        self.ref = Database.database().reference()
        self.ref.child("buildings").child(userID!).child(self.selected_building as String).child("images").child(image.key as! String).removeValue()
        
        let storageRef = Storage.storage().reference()
        storageRef.child("images").child("buildings").child(userID!).child(self.selected_building as String).child(image.value as! String).delete { (error) in
            
            if let error = error {
                print("error occurred")
                print(error.localizedDescription)
            } else {
                print("success")
            }
            
        }
    }

}
