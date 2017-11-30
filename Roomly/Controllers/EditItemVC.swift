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

class EditItemVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Variables
    var ref: DatabaseReference!
    var imagesDirectoryPath:String!
    var saved_image = ""
    var selected_building = "" as NSString
    var selected_item = "" as NSString
    var selected_room = "" as NSString
    var itemNameText = ""
    var itemDescriptionText = ""
    var purchaseDateText = ""
    var purchaseAmountText = ""
    var datePicker = UIDatePicker()
    var toolBar = UIToolbar()
    var textField = UITextField()
    
    // Outlets
    @IBOutlet weak var itemNameTxt: UITextField!
    @IBOutlet weak var itemDescriptionTxt: UITextField!
    @IBOutlet weak var purchaseAmountTxt: UITextField!
    @IBOutlet weak var purchaseDateTxt: UITextField!
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
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
    @IBAction func closePressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func submitPressed(_ sender: Any) {
        spinner.startAnimating()
        spinner.isHidden = false
        
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
        
        let item = Item(id: key, itemName: itemNameText, itemDescription: itemDescriptionText, imageName: self.saved_image, purchaseAmount: purchaseAmountText, purchaseDate: purchaseDateText as String, roomId: selected_room as String, uid: userID)
        
        let post = [
            "itemName" : item.itemName,
            "itemDescription" : item.itemDescription,
            "imageName": item.imageName,
            "purchaseAmount" : item.purchaseAmount,
            "purchaseDate" : item.purchaseDate,
            "roomId" : item.roomId,
            "uid" : item.uid,
            "id" : item.id,
            ]
        
        let childUpdates = ["/items/\(userID)/\(selected_room)/\(key)": post]
        self.ref.updateChildValues(childUpdates)
        spinner.stopAnimating()
        spinner.isHidden = true
        
        DataService.instance.updateItem(new_item: item)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        let userID = Auth.auth().currentUser?.uid
        self.ref = Database.database().reference()
        self.ref.child("items").child(userID!).child(self.selected_room as String).child(self.selected_item as String).removeValue()
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
        selected_building = DataService.instance.getSelectedBuilding()
        selected_item = DataService.instance.getSelectedItem()
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
        
        createDatePicker()
        createToolBar()
        addTextField()
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                let userID = Auth.auth().currentUser?.uid
                self.ref.child("items").child(userID!).child(self.selected_room as String).child(self.selected_item as String).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    
                    self.itemNameTxt.text = value?["itemName"] as? String
                    self.itemDescriptionTxt.text = value?["itemDescription"] as? String
                    self.purchaseAmountTxt.text = value?["purchaseAmount"] as? String
                    self.purchaseDateTxt.text = value?["purchaseDate"] as? String
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
