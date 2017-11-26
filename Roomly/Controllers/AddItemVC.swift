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

class AddItemVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    
    // Outlets
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var itemDescription: UITextField!
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var purchaseDate: UITextField!
    @IBOutlet weak var purchaseAmount: UITextField!
    @IBOutlet weak var stackView: UIStackView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Actions
    
    @IBAction func openCameraButton(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func closePicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitPicked(_ sender: Any) {
        spinner.startAnimating()
        spinner.isHidden = false
        
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let key = self.ref.child("items").child(userID).childByAutoId().key
        
        if itemName.text != "" {
            self.itemNameText = self.itemName.text!
        }
        
        if itemDescription.text != "" {
            self.itemDescriptionText = self.itemDescription.text!
        }
        
        if purchaseAmount.text != "" {
            self.purchaseAmountText = self.purchaseAmount.text!
        }
        
        if purchaseDate.text != "" {
            self.purchaseDateText = self.purchaseDate.text!
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
        self.dismiss(animated: true, completion: nil)
    }
    
    func addTextField() {
//        view.addSubview(textField)
//        stackView.addSubview(textField)
//        purchaseDate.translatesAutoresizingMaskIntoConstraints = false
//        purchaseDate.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40.0).isActive = true
//        purchaseDate.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40.0).isActive = true
//        purchaseDate.topAnchor.constraint(equalTo: view.topAnchor, constant: 40.0).isActive = true
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
