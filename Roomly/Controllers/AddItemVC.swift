//
//  AddItem.swift
//  Roomly
//
//  Created by Jason Shultz on 11/25/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class AddItemVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Variables
    var ref: DatabaseReference!
    var imagesDirectoryPath:String!
    var saved_image = ""
    var selected_room = "" as NSString
    var itemNameText = ""
    var itemDescriptionText = ""
    var purchaseDateText = ""
    var purchaseAmountText = ""
    var datePicker = UIDatePicker()
    var toolBar = UIToolbar()
    var textField = UITextField()
    var images: [UIImage] = []
    
    // Needed for Camera / Photo Gallery
    static let shared = CameraHandler()
    fileprivate var currentVC: UIViewController!
    //MARK: Internal Properties
    var imagePickedBlock: ((UIImage) -> Void)?
    
    // Outlets
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var itemDescription: UITextField!
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var purchaseDate: UITextField!
    @IBOutlet weak var purchaseAmount: UITextField!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var pendingImagesCollection: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selected_room = DataService.instance.getSelectedRoom()
        
        self.ref = Database.database().reference()
        self.ref.keepSynced(true)
        
        pendingImagesCollection.dataSource = self
        pendingImagesCollection.delegate = self
        
        // Do any additional setup after loading the view.
        
        if !FileManager.default.fileExists(atPath: IMAGE_DIRECTORY_PATH) {
            do {
                try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: IMAGE_DIRECTORY_PATH), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("AddItemVC: ")
                print(error)
            }
        }
        
        createDatePicker()
        createToolBar()
        addTextField()
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
        CameraHandler.shared.showActionSheet(vc: self)
        CameraHandler.shared.imagePickedBlock = { (image) in
            self.images.append(image)
            self.pendingImagesCollection.reloadData()
        }
    }
    
    @IBAction func cancelPicked(_ sender: Any) {
        performSegue(withIdentifier: "unwindToItemsVC", sender: self)
    }
    
    @IBAction func submitPicked(_ sender: Any) {
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.ref.child("items").child(userID).childByAutoId().key
        
        guard let itemNameText = itemName.text , itemName.text != "" else {
            return
        }
        
        guard let itemDescriptionText = itemDescription.text , itemDescription.text != "" else {
            return
        }
        
        guard let purchaseAmountText = purchaseAmount.text , purchaseAmount.text != "" else {
            return
        }
        
        guard let purchaseDateText = purchaseDate.text , purchaseDate.text != "" else {
            return
        }
        
        let item = Item(id: key, itemName: itemNameText, itemDescription: itemDescriptionText, imageName: self.saved_image, images: NSDictionary(), purchaseAmount: purchaseAmountText, purchaseDate: purchaseDateText as String, roomId: selected_room as String, uid: userID)
        
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
        
        let childUpdates = ["/items/\(userID)/\(selected_room)/\(key)": post]
        self.ref.updateChildValues(childUpdates)
        
        self.images.forEach { (image) in
            CloudStorage.instance.saveImageToFirebase(key: key, image: image, user_id: userID, destination: "items", second_key: item.roomId as! String)
        }
        
        performSegue(withIdentifier: "unwindToItemsVC", sender: self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func addTextField() {
        purchaseDate.placeholder = "Select date"
        purchaseDate.borderStyle = .roundedRect
        purchaseDate.inputView = datePicker
        purchaseDate.inputAccessoryView = toolBar
    }
    
    func createDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(datePicker:)), for: .valueChanged)
    }
    
    @objc func datePickerValueChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        purchaseDate.text = dateFormatter.string(from: datePicker.date)
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
        
        purchaseDate.text = dateFormatter.string(from: Date()) // 2
        
        purchaseDate.resignFirstResponder()
    }
    
    @objc func doneButtonPressed(sender: UIBarButtonItem) {
        purchaseDate.resignFirstResponder()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("image count \(self.images.count)")
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
