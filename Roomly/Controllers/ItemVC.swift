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
    @IBOutlet weak var slideShowCollection: UICollectionView!
    @IBOutlet weak var roomDetailsLabel: UILabel!
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.slideShowCollection {
            return self.slideShowImages.count
        }
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.slideShowCollection {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SlideShowCell", for: indexPath) as? SlideShowCell {
                let image = self.slideShowImages[indexPath.row]
                cell.updateView(image: image)
                return cell
            }
            return SlideShowCell()
        }
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? ItemCell {
            let item = items[indexPath.row]
            cell.updateViews(item: item)
            return cell
        }
        return ItemCell()
        
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
        itemsCollection.dataSource = self
        itemsCollection.delegate = self
        slideShowCollection.dataSource = self
        slideShowCollection.delegate = self
        
        self.view.addSubview(itemsCollection)
        self.view.addSubview(itemsCollection)
        self.slideShowImages = [UIImage]()
        items = [Item]()
        
        if Auth.auth().currentUser != nil {
            // User is signed in.
            self.loadData()
            items = []
            self.itemsCollection.reloadData()
        } else {
            DataService.instance.resetBuildings()
            
            self.itemsCollection.reloadData()
            print("No user is signed in.")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.itemsCollection {
            let item = items[indexPath.row]
            DataService.instance.setSelectedItem(item: item)
            performSegue(withIdentifier: "ShowItemVC", sender: item)
        }
    }
    
    func initItems(room: Room) {
        items = DataService.instance.getItemsForRoom(forRoomId: room.id)
        navigationItem.title = room.roomName! as String
    }
    
    func loadData() {
        
        self.ref = Database.database().reference()
        
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
                    self.slideShowImages = [UIImage]()
                    if ((slideShowDictionary) != nil) {
                        let total = slideShowDictionary?.count
                        
                        slideShowDictionary?.forEach({ (_,value) in
                            CloudStorage.instance.downloadImage(reference: destination, image_key: value as! String, completion: { (image) in
                                self.slideShowImages.append(image)
                                self.slideShowCollection.reloadData()
                            })
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
            }, withCancel: { (error) in
                print(error)
            })
    }
    
    // Actions
    @IBAction func unwindToItemsVC(segue:UIStoryboardSegue) {

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
