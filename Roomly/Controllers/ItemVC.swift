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
    var total_items = 0
    var total_item_value = Double()
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private(set) public var items = [Item]()
    
    // Outlets
    @IBOutlet weak var itemsCollection: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var roomImage: UIImageView!
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
    
    override func viewWillAppear(_ animated: Bool) {
        
        handle = Auth.auth().addStateDidChangeListener() { auth, user in
            
            if user != nil {
                // User is signed in.
                self.itemsCollection.reloadData()
            } else {
                DataService.instance.resetBuildings()
                self.itemsCollection.reloadData()
                print("No user is signed in.")
            }
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
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

                        let destination = "rooms/\(userID)/\(building_id)/\(room_id)/"
                        
                        CloudStorage.instance.loadTopImage(destination: destination, saved_image: self.saved_room_image, completion: { (image) in
                            self.roomImage.image = image
                        })
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
                    postDict.forEach({ (arg) in
                        let (_, value) = arg
                        let dataChange = value as! [String: AnyObject]
                        
                        let id = dataChange["id"] as! String
                        let itemName = dataChange["itemName"] as! String
                        let itemDescription = dataChange["itemDescription"] as! String
                        let imageName = dataChange["imageName"] as! String
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
                        
                        let item = Item(id: id, itemName: itemName, itemDescription: itemDescription, imageName: imageName, purchaseAmount: purchaseAmount, purchaseDate: purchaseDate, roomId: roomId, uid: uid)
                        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let showItemVC = segue.destination as? ShowItemVC {
            let barBtn = UIBarButtonItem()
            barBtn.title = ""
            navigationItem.backBarButtonItem = barBtn
            assert(sender as? Item != nil)
        }
    }
    
    // Actions
    
    @IBAction func addItemPressed(_ sender: Any) {
        let addItem = AddItemVC()
        addItem.modalPresentationStyle = .custom
        present(addItem, animated: true, completion: nil)
    }
    
    @IBAction func editPressed(_ sender: Any) {
        let editRoom = EditRoomVC()
        editRoom.modalPresentationStyle = .custom
        present(editRoom, animated: true, completion: nil)
    }
    
    
}
