//
//  RoomVC.swift
//  Roomly
//
//  Created by Jason Shultz on 10/9/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class RoomVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Variables
    var handle: AuthStateDidChangeListenerHandle?
    var saved_house_image = ""
    var ref: DatabaseReference!
    let selected_building = DataService.instance.getSelectedBuilding()
    var slideShowDictionary = NSDictionary()
    var slideShowImages = [UIImage]()
    var total_items = 0
    var total_item_value = Double()
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    // Outlets
    @IBOutlet weak var roomsCollection: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var houseImage: UIImageView!
    @IBOutlet weak var houseDetails: UILabel!
    @IBOutlet weak var slideShowView: UIView!
    
    
    private(set) public var items = [Item]()
    private(set) public var rooms = [Room]()
    
    override func viewWillAppear(_ animated: Bool) {
        
        handle = Auth.auth().addStateDidChangeListener() { auth, user in
            
            if user != nil {
                // User is signed in.
                self.roomsCollection.reloadData()
            } else {
                DataService.instance.resetBuildings()
                self.roomsCollection.reloadData()
                print("No user is signed in.")
            }
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ref = Database.database().reference()
        roomsCollection.dataSource = self
        roomsCollection.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                guard let userID = Auth.auth().currentUser?.uid else { return }
                let buildingRef = self.ref.child("buildings").child(userID)
                buildingRef.keepSynced(true)
                
                buildingRef.child(self.selected_building as String).observe(DataEventType.value, with: { (snapshot) in
                    
                    let value = snapshot.value as? NSDictionary
                    
                    if ((value) != nil) {
                        let building_id = value?["id"] as! String
                        let saved_image = value?["imageName"] as! String
                        let user_id = userID as! String
                        let destination = "/images/buildings/\(userID)/\(building_id)/"
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
                            
                        }
                        
                    }
                })

                // User is signed in.
                self.getRooms()
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

    func initRooms(building: Building) {
        navigationItem.title = building.buildingName! as String
        self.getRooms()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rooms.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoomCell", for: indexPath) as? RoomCell {
            let room = rooms[indexPath.row]
            cell.updateViews(room: room)
            return cell
        }
        return RoomCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let room = rooms[indexPath.row]
        DataService.instance.setSelectedRoom(room: room)
        performSegue(withIdentifier: "ItemVC", sender: room)
    }
    
    func getRoomItemValues(rooms: [Room], userID: String) {
        var single_item = 0
        var single_item_value = Double()
        rooms.forEach { (room) in
            self.ref.child("items").child(userID).child(room.id as String).observe(DataEventType.value, with: { (snapshot) in
//                self.spinner.startAnimating()
                let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                DataService.instance.resetItems()
                
                postDict.forEach({ (arg) in
                    let (_, value) = arg
                    let dataChange = value as! [String: AnyObject]
                    single_item = single_item + 1
                    _ = dataChange["id"] as? String
                    if dataChange["purchaseAmount"] != nil {
                        if let purchaseDate = (dataChange["purchaseAmount"]as? NSString)?.doubleValue {
                            single_item_value = single_item_value + purchaseDate
                        }
                    }
                })
                if (single_item > 0) {
                    self.houseDetails.text = "There are \(single_item) item(s) totalling \(String(format: "$%.02f", single_item_value))"
                } else {
                    self.houseDetails.text = "There are no items."
                }
            }, withCancel: { (error) in
                print(error)
            })
        }
    }
    
    // This gets all the Rooms In the Building.
    func getRooms() {
        self.ref = Database.database().reference()
        self.ref.keepSynced(true)
        guard let userID = Auth.auth().currentUser?.uid else { return }
        self.ref.child("rooms").child(userID).child(self.selected_building as String).observe(DataEventType.value, with: { (snapshot) in
            self.spinner.startAnimating()
            let postDict = snapshot.value as? [String : AnyObject] ?? [:]
            DataService.instance.resetRooms()
            
            postDict.forEach({ (arg) in
                let (_, value) = arg
                let dataChange = value as! [String: AnyObject]
                
                let id = dataChange["id"] as! String
                
                var images = NSDictionary()
                if ((dataChange["images"]) != nil) {
                    images = dataChange["images"] as! NSDictionary
                } else {

                }
                
                let roomName = dataChange["roomName"] as! String
                let roomDescription = dataChange["roomDescription"] as! String
                let imageName = dataChange["imageName"] as! String
                let buildingId = dataChange["buildingId"] as! String
                let uid = dataChange["uid"] as! String
                let room = Room(id: id, roomName: roomName, roomDescription: roomDescription, imageName: imageName, images: images, buildingId: buildingId, uid: uid)
                DataService.instance.setRoom(room: room)
                self.rooms = DataService.instance.getRoomsForBuilding(forBuildingId: self.selected_building)
                self.getRoomItemValues(rooms: self.rooms, userID: userID)
                self.roomsCollection.reloadData()
                self.spinner.stopAnimating()
            })
            
            if (self.rooms.count == 0) {
                self.houseDetails.text = "There are no rooms or items."
            }
            
        }, withCancel: { (error) in
            print("getRooms: ")
            print(error)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let itemVC = segue.destination as? ItemVC {
            NotificationCenter.default.removeObserver(SlideShowVC.notificationName)
            let barBtn = UIBarButtonItem()
            barBtn.title = ""
            assert(sender as? Room != nil)
            itemVC.initItems(room: sender as! Room)
        }
        
    }
    
    // Actions
    @IBAction func addRoomPressed(_ sender: Any) {
//        let addRoom = AddRoomVC()
//        addRoom.modalPresentationStyle = .custom
//        present(addRoom, animated: true, completion: nil)
    }
    
    @IBAction func editBuildingPressed(_ sender: Any) {
        let editBuilding = EditBuildingVC()
        editBuilding.modalPresentationStyle = .custom
        present(editBuilding, animated: true, completion: nil)
    }

    
    
}
