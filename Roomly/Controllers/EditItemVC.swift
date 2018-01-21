//
//  EditItemVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/26/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class EditItemVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Variables
    
    var availableBuildingsDict = [Building]()
    var availableBuildings = [(buildingId:String, buildingName:String)]()
    var availableRoomsDict = [Room]()
    var availableRooms = [(roomId:String, roomName:String, buildingId: String)]()
    var datePicker = UIDatePicker()
    var imageDictionary = NSDictionary()
    var images: [UIImage] = []
    var imagesDirectoryPath:String!
    var item = Item(id: "", itemName: "", itemDescription: "", imageName: "", images: NSDictionary(), purchaseAmount: "", purchaseDate: "", roomId: "", uid: "")
    var itemDescriptionText = ""
    var itemNameText = ""
    var purchaseAmountText = ""
    var purchaseDateText = ""
    var new_building = "" as NSString
    var new_room = "" as NSString
    var ref: DatabaseReference!
    var saved_image = ""
    var selected_building = "" as NSString
    var selected_item = "" as NSString
    var selected_room = "" as NSString
    var toolBar = UIToolbar()
    var textField = UITextField()
    var userID = ""
    
    // Outlets
    @IBOutlet weak var itemNameTxt: UITextField!
    @IBOutlet weak var itemDescriptionTxt: UITextField!
    @IBOutlet weak var purchaseAmountTxt: UITextField!
    @IBOutlet weak var purchaseDateTxt: UITextField!
    @IBOutlet weak var locatedInBuildingTxt: UITextField!
    @IBOutlet weak var locatedInRoomTxt: UITextField!
    @IBOutlet weak var editImagesCollection: UICollectionView!
    
    // Actions
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func openCameraButton(_ sender: Any) {
        CameraHandler.shared.showActionSheet(vc: self)
        CameraHandler.shared.imagePickedBlock = { (image) in
            let key = self.selected_item as String
            guard let userID = Auth.auth().currentUser?.uid else { return }
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "items", second_key: self.selected_room as String)
        }
    }
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        performSegue(withIdentifier: "unwindToShowItemVC", sender: self)
    }
    @IBAction func submitPressed(_ sender: Any) {
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.selected_item as String
        
        guard let itemNameText = itemNameTxt.text , itemNameTxt.text != "" else {
            return
        }
        
        guard let itemDescriptionText = itemDescriptionTxt.text , itemDescriptionTxt.text != "" else {
            return
        }
        
        guard let purchaseAmountText = purchaseAmountTxt.text , purchaseAmountTxt.text != "" else {
            return
        }
        
        guard let purchaseDateText = purchaseDateTxt.text , purchaseDateTxt.text != "" else {
            return
        }
        
        let origin = "/items/\(userID)/\(self.selected_room)/\(key)"
        var destination:String = "/items/\(userID)/\(self.selected_room)/\(key)"
        var room_id = selected_room
        
        // I am checking to see if a new room is being chosen. If the new_room doesn't match selected_room then I know that they are moving items
        if ((self.new_room as String != self.selected_room as String)) {
            // they are moving rooms
            
            let new_destination = "/items/\(userID)/\(self.new_room)/\(key)"
            
            room_id = new_room
            destination = new_destination
            
        } else {
            // they are not moving rooms.
        }
        
        let item = Item(id: key, itemName: itemNameText, itemDescription: itemDescriptionText, imageName: self.saved_image, images: self.imageDictionary, purchaseAmount: purchaseAmountText, purchaseDate: purchaseDateText as String, roomId: room_id as String, uid: userID)
        
        let post = [
            "itemName" : item.itemName,
            "itemDescription" : item.itemDescription,
            "imageName": item.imageName,
            "images": item.images,
            "purchaseAmount" : item.purchaseAmount,
            "purchaseDate" : item.purchaseDate,
            "roomId" : item.roomId,
            "uid" : item.uid,
            "id" : item.id,
            ] as [String : Any]
        
        let childUpdates = [destination: post]
        
        self.ref.updateChildValues(childUpdates) { (error, snapshot) in
            if (error != nil) {
                print("update of item failed")
            } else {
                // We are changing rooms
                print("do they match: ")
                print("new room \(self.new_room)")
                print("old room \(self.selected_room)")
                print(self.new_room as String != self.selected_room as String)
                if ((self.new_room as String != self.selected_room as String)) {
                    CloudStorage.instance.moveImage(origin: origin, destination: destination, new_room: self.new_room as String, user_id: userID, item_id: key)
                    
                    let originRef = self.ref.child(origin)
                    originRef.removeValue { error, _ in
                        if ((error) != nil) {
                            print("deleting item: ")
                            print(error!)
                        }
                    }
                    
                    self.images.forEach { (image) in
                        CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "items", second_key: item.roomId! as String)
                    }
                    
                } else { // We are not changing rooms.
                    self.images.forEach { (image) in
                        CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "items", second_key: item.roomId! as String)
                    }
                }
                
                CloudData.instance.getBuildingById(userId: userID, buildingId: self.selected_building as String, completion: { (building) in

                    DataService.instance.setSelectedBuilding(building: building)
                    CloudData.instance.getRoomById(userId: userID, buildingId: self.selected_building as String, roomId: self.selected_room as String, completion: { (room) in
                        DataService.instance.setSelectedRoom(room: room)
                        DataService.instance.updateItem(new_item: item)
                        DataService.instance.setSelectedItem(item: item)
                        
                        if ((self.new_room as String != self.selected_room as String)) {
                            self.performSegue(withIdentifier: "unwindToItemsVC", sender: self)

                        } else {
                            self.performSegue(withIdentifier: "unwindToShowItemVC", sender: self)

                        }
                    })
                })
                
            }
        }
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        let userID = Auth.auth().currentUser?.uid
        self.ref = Database.database().reference()
        self.ref.child("items").child(userID!).child(self.selected_room as String).child(self.selected_item as String).removeValue()
        performSegue(withIdentifier: "unwindToItemsVC", sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let buildingPicker = UIPickerView()
        let roomPicker = UIPickerView()
        editImagesCollection.dataSource = self
        editImagesCollection.delegate = self
        
        locatedInBuildingTxt.inputView = buildingPicker
        locatedInRoomTxt.inputView = roomPicker
        
        buildingPicker.delegate = self
        roomPicker.delegate = self
        
        selected_building = DataService.instance.getSelectedBuilding()
        selected_item = DataService.instance.getSelectedItem()
        selected_room = DataService.instance.getSelectedRoom()

        self.ref = Database.database().reference()
        self.ref.keepSynced(true)
        
        // Do any additional setup after loading the view.
        
        if !FileManager.default.fileExists(atPath: IMAGE_DIRECTORY_PATH) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: IMAGE_DIRECTORY_PATH), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
        
        createDatePicker()
        createToolBar()
        addTextField()
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                let userID = Auth.auth().currentUser?.uid
                self.userID = userID!
                self.ref.child("items").child(userID!).child(self.selected_room as String).child(self.selected_item as String).observe(DataEventType.value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    
                    if (value != nil) {
                        self.itemNameTxt.text = value?["itemName"] as? String
                        self.itemDescriptionTxt.text = value?["itemDescription"] as? String
                        self.purchaseAmountTxt.text = value?["purchaseAmount"] as? String
                        self.purchaseDateTxt.text = value?["purchaseDate"] as? String
                        self.saved_image = (value?["imageName"] as? String)!
                        if ((value?["images"] ) != nil) {
                            self.imageDictionary = (value?["images"] as? NSDictionary)!
                            self.editImagesCollection.reloadData()
                        }
                        
                        let imageURL = URL(fileURLWithPath: IMAGE_DIRECTORY_PATH).appendingPathComponent(value?["imageName"] as! String)
                        let image    = UIImage(contentsOfFile: imageURL.path)
                    }
                                        
                }) { (error) in
                    print(error.localizedDescription)
                }
                // Get name and id of currently assigned Building
                self.ref.child("buildings").child(userID!).child(self.selected_building as String).observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    self.locatedInBuildingTxt.text = value?["buildingName"] as? String
                    self.new_building = (value?["id"] as? NSString)!
                })
                // Get name and id of currently assigned Room
                self.ref.child("rooms").child(userID!).child(self.selected_building as String).child(self.selected_room as String).observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    self.locatedInRoomTxt.text  = value?["roomName"] as? String
                    self.new_room = (value?["id"] as? NSString)!
                })
                
                CloudData.instance.getAllBuildings(userID: userID!, completion: { (buildings) in
                    self.availableBuildingsDict = buildings
                    self.availableBuildingsDict.forEach({ (building) in
                        self.availableBuildings.append((buildingId: building.id as String, buildingName: building.buildingName as String))
                    })
                    
                })
                
                CloudData.instance.getAllRooms(userID: userID!, buildingId: self.selected_building as String, completion: { (rooms) in
                    self.availableRoomsDict = rooms
                    self.availableRoomsDict.forEach({ (room) in
                        self.availableRooms.append((roomId: room.id as String, roomName: room.roomName as String, buildingId: room.buildingId as String))
                    })
                })
                
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
    
    func addTextField() {
        purchaseDateTxt.placeholder = "Select date"
        purchaseDateTxt.borderStyle = .roundedRect
        purchaseDateTxt.inputView = datePicker
        purchaseDateTxt.inputAccessoryView = toolBar
    }
    
    func createDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(datePicker:)), for: .valueChanged)
    }
    
    @objc func datePickerValueChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        purchaseDateTxt.text = dateFormatter.string(from: datePicker.date)
    }
    
    func createToolBar() {
        toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
        
        let todayButton = UIBarButtonItem(title: "Today", style: .plain, target: self, action: #selector(todayButtonPressed(sender:)))
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(sender:)))
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width/3, height: 40))
        label.text = "Choose your Date"
        let labelButton = UIBarButtonItem(customView:label)
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.setItems([todayButton,flexibleSpace,labelButton,flexibleSpace,doneButton], animated: true)
    }
    
    @objc func todayButtonPressed(sender: UIBarButtonItem) {
        let dateFormatter = DateFormatter() // 1
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        purchaseDateTxt.text = dateFormatter.string(from: Date()) // 2
        
        purchaseDateTxt.resignFirstResponder()
    }
    
    @objc func doneButtonPressed(sender: UIBarButtonItem) {
        purchaseDateTxt.resignFirstResponder()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if locatedInBuildingTxt.isFirstResponder{
            return self.availableBuildings.count
        } else {
            return self.availableRooms.count
        }
    }
    
    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if locatedInBuildingTxt.isFirstResponder{
            self.new_building = self.availableBuildings[row].buildingId as NSString
            return self.availableBuildings[row].buildingName
        } else {
            self.new_room = self.availableRooms[row].roomId as NSString
            return self.availableRooms[row].roomName
        }
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if locatedInBuildingTxt.isFirstResponder{
            self.locatedInBuildingTxt.text = availableBuildings[row].buildingName
            self.new_building = availableBuildings[row].buildingId as NSString
            self.availableRoomsDict = [Room]()
            CloudData.instance.getAllRooms(userID: self.userID, buildingId: availableBuildings[row].buildingId as String, completion: { (rooms) in
                self.availableRoomsDict = rooms
                self.availableRooms = [(roomId:String, roomName:String, buildingId: String)]()
                self.availableRoomsDict.forEach({ (room) in
                    self.availableRooms.append((roomId: room.id as String, roomName: room.roomName as String, buildingId: room.buildingId as String))
                })
            })
        } else {
            self.locatedInRoomTxt.text = availableRooms[row].roomName
            self.new_room = availableRooms[row].roomId as NSString
        }
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
            cell.updateViews(image: image, image_category: "items", category_key_1: self.selected_room as! String, user_id: userID!, category_key_2: self.selected_item as! String)
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
        self.ref.child("items").child(userID!).child(self.selected_room as String).child(self.selected_item as String).child("images").child(image.key as! String).removeValue()
        
        let storageRef = Storage.storage().reference()
        storageRef.child("images").child("items").child(userID!).child(self.selected_room as String).child(self.selected_item as String).child(image.value as! String).delete { (error) in
            
            if let error = error {
                print("error occurred")
                print(error.localizedDescription)
            } else {
                print("success")
            }
        }
    }

}
