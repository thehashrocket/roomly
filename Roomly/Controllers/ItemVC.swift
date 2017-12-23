//
//  ItemVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/25/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class ItemVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Variables
    var ref: DatabaseReference!
    let selected_building = DataService.instance.getSelectedBuilding()
    let selected_room = DataService.instance.getSelectedRoom()
    var handle: AuthStateDidChangeListenerHandle?
    var saved_room_image = ""
    var slideShowDictionary = NSDictionary()
    var slideShowImages = [UIImage]()
    var total_items = 0
    var total_item_value = Double()
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private(set) public var items = [Item]()
    
    // Outlets
    @IBOutlet weak var itemsCollection: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    @IBOutlet weak var roomDetailsLabel: UILabel!
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? ItemCell {
            let item = items[indexPath.row]
            cell.updateViews(item: item)
            return cell
        }
        return ItemCell()
    }
    
    func collectionview(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var numOfColumns:CGFloat = 3
        
        if UIScreen.main.bounds.width > 320 {
            numOfColumns = 4
        }
        
        let spaceBetweenCells:CGFloat = 10
        let padding:CGFloat = 40
        let cellDimension = ((collectionView.bounds.width - padding) - (numOfColumns - 1) * spaceBetweenCells) / numOfColumns
        
        return CGSize(width: cellDimension, height: cellDimension)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let showItemVC = segue.destination as? ShowItemVC {
            NotificationCenter.default.removeObserver(SlideShowVC.notificationName)
            let barBtn = UIBarButtonItem()
            barBtn.title = ""
            assert(sender as? Item != nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("in view did load")
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        handle = Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                print("in view will appear")
                self.loadData()
//                self.itemsCollection.reloadData()
            } else {
                DataService.instance.resetBuildings()
                self.itemsCollection.reloadData()
                print("No user is signed in.")
            }
        }
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        DataService.instance.setSelectedItem(item: item)
        performSegue(withIdentifier: "ShowItemVC", sender: item)
    }
    
    func initItems(room: Room) {
        items = DataService.instance.getItemsForRoom(forRoomId: room.id)
        navigationItem.title = room.roomName! as String
    }
    
    func loadData() {
        itemsCollection.dataSource = self
        itemsCollection.delegate = self
        
        self.ref = Database.database().reference()
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                
                guard let userID = Auth.auth().currentUser?.uid else { return }
                let roomRef = self.ref.child("rooms").child(userID).child(self.selected_building as String).child(self.selected_room as String)
                roomRef.keepSynced(true)
                
                // Get the Room in the building so we can get the image of the room.
                roomRef.observe(DataEventType.value, with: { (snapshot) in
                    
                    let value = snapshot.value as? NSDictionary
                    if ((value) != nil) {
                        self.saved_room_image = (value?["imageName"] as? String)!
                        let building_id = (value?["buildingId"] as? String)!
                        let room_id = (value?["id"] as? String)!
                        let destination = "/images/rooms/\(userID)/\(building_id)/\(room_id)/"
                        
                        let slideShowDictionary = value?["images"] as? NSDictionary
                        self.slideShowImages.removeAll()
                        if ((slideShowDictionary) != nil) {
                            let total = slideShowDictionary?.count
                            var count = 0
                            
                            slideShowDictionary?.forEach({ (_,value) in
                                CloudStorage.instance.downloadImage(reference: destination, image_key: value as! String, completion: { (image) in
                                    self.slideShowImages.append(image)
                                })
                                count = count + 1
                                if (count == total) {
                                    NotificationCenter.default.post(name: SlideShowVC.notificationName, object: nil, userInfo:["images": self.slideShowImages])
                                }
                            })
                            
                            CloudData.instance.getRoomById(userId: userID, buildingId: building_id, roomId: room_id, completion: { (room) in
                                self.title = room.roomName as String
                            })
                            
                        } else {
                            
                        }
                    }
                    
                })
                
                let itemsRef = self.ref.child("items").child(userID).child(self.selected_room as String)
                itemsRef.keepSynced(true)
                
                itemsRef.observe(DataEventType.value, with: { (snapshot) in
                    self.spinner.startAnimating()
                    let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                    DataService.instance.resetItems()
                    
                    self.total_items = postDict.count
                    self.total_item_value = 0
                    if (postDict.count == 0) {
                        self.roomDetailsLabel.text = "There are no items in this room."
                    }
                    postDict.forEach({ (arg) in
                        let (_, value) = arg
                        let dataChange = value as! [String: AnyObject]
                        
                        let images = NSDictionary()
                        let id = dataChange["id"] as! String
                        let itemName = dataChange["itemName"] as! String
                        let itemDescription = dataChange["itemDescription"] as! String
                        let imageName = dataChange["imageName"] as! String
                        if ((dataChange["images"]) != nil) {
                            let images = dataChange["images"] as? NSDictionary
                        }
                        
                        let purchaseAmount = ""
                        if let val = dataChange["purchaseAmount"] {
                            let purchaseAmount = dataChange["purchaseAmount"] as! String
                            if let purchaseDate = (dataChange["purchaseAmount"]as? NSString)?.doubleValue {
                                self.total_item_value = self.total_item_value + purchaseDate
                            }
                        }
                        var purchaseDate = ""
                        if let val = dataChange["purchaseDate"] {
                            let purchaseDate = dataChange["purchaseDate"] as! String
                        }
                        let roomId = dataChange["roomId"] as! String
                        let uid = dataChange["uid"] as! String
                        
                        let item = Item(id: id, itemName: itemName, itemDescription: itemDescription, imageName: imageName, images: images, purchaseAmount: purchaseAmount, purchaseDate: purchaseDate, roomId: roomId, uid: uid)
                        
                        DataService.instance.setItem(item: item)
                        
                        self.items = DataService.instance.getItemsForRoom(forRoomId: self.selected_room)
                        self.itemsCollection.reloadData()
                        self.roomDetailsLabel.text = "There are \(self.total_items) item(s) totalling \(String(format: "$%.02f", self.total_item_value))"
                    })
                    self.spinner.stopAnimating()
                }, withCancel: { (error) in
                    print(error)
                })
                
            } else {
                // TODO: Segue to WelcomeVC here.
                print("No user is signed in.")
            }
        }
    }
    
    // Actions
    @IBAction func unwindToItemsVC(segue:UIStoryboardSegue) {
        loadData()
    }
    
    @IBAction func addItemPressed(_ sender: Any) {
//        let addItem = AddItemVC()
//        addItem.modalPresentationStyle = .custom
//        present(addItem, animated: true, completion: nil)
    }
    
    @IBAction func editPressed(_ sender: Any) {
//        let editRoom = EditRoomVC()
//        editRoom.modalPresentationStyle = .custom
//        present(editRoom, animated: true, completion: nil)
    }
    
    
}
