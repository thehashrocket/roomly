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

class RoomVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
    
    private(set) public var items = [Item]()
    private(set) public var rooms = [Room]()
    
    // Outlets
    @IBOutlet weak var roomsCollection: UICollectionView!
    @IBOutlet weak var houseImage: UIImageView!
    @IBOutlet weak var houseDetails: UILabel!
    @IBOutlet weak var slideShowCollection: UICollectionView!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let itemVC = segue.destination as? ItemVC {
            NotificationCenter.default.removeObserver(SlideShowVC.notificationName)
            let barBtn = UIBarButtonItem()
            barBtn.title = ""
            assert(sender as? Room != nil)
            itemVC.initItems(room: sender as! Room)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomsCollection.dataSource = self
        roomsCollection.delegate = self
        
        slideShowCollection.dataSource = self
        slideShowCollection.delegate = self
        
        self.view.addSubview(roomsCollection)
        self.view.addSubview(slideShowCollection)
        
        if Auth.auth().currentUser != nil {
            // User is signed in.
            self.loadData()
        } else {
            DataService.instance.resetBuildings()
            DataService.instance.resetRooms()
            self.roomsCollection.reloadData()
            print("No user is signed in.")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.slideShowCollection {
            return self.slideShowImages.count // Replace with count of your data for collectionViewA
        }
        return rooms.count // Replace with count of your data for collectionViewB
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
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RoomCell", for: indexPath) as? RoomCell {
            let room = rooms[indexPath.row]
            cell.updateViews(room: room)
            return cell
        }
        return RoomCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.slideShowCollection {
            return CGSize(width: self.slideShowCollection.frame.width, height: self.slideShowCollection.frame.height)
        }
        
        return CGSize(width: self.roomsCollection.frame.width * 0.3, height: self.roomsCollection.frame.width * 0.3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == self.roomsCollection {
            let room = rooms[indexPath.row]
            DataService.instance.setSelectedRoom(room: room)
            performSegue(withIdentifier: "ItemVC", sender: room)
        }
    }
    
    func getRoomItemValues(rooms: [Room], userID: String) {
        var single_item = 0
        var single_item_value = Double()
        rooms.forEach { (room) in
            self.ref.child("items").child(userID).child(room.id as String).observe(DataEventType.value, with: { (snapshot) in
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
        DataService.instance.resetRooms()
        self.ref = Database.database().reference()
        self.ref.keepSynced(true)
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        self.ref.child("rooms").child(userID).child(self.selected_building as String).observe(DataEventType.value, with: { (snapshot) in
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
            })
            
            if (self.rooms.count == 0) {
                self.houseDetails.text = "There are no rooms or items."
            }
        }) { (error) in
            print("getRooms: ")
            print(error)
        }
        
    }
    
    func initRooms(building: Building) {
        navigationItem.title = building.buildingName! as String
        self.getRooms()
    }
    
    func loadData() {
        self.ref = Database.database().reference()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
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
                
                if ((slideShowDictionary) != nil) {
                    self.slideShowImages = [UIImage]()
                    self.slideShowCollection.reloadData()
                    slideShowDictionary?.forEach({ (arg) in
                        
                        let (_, value) = arg
                        CloudStorage.instance.downloadImage(reference: destination, image_key: value as! String, completion: { (image, error)  in
                            if let error = error {
                                print(error)
                            } else {
                                self.slideShowImages.append(image!)
                                self.slideShowCollection.reloadData()
                            }
                        })
                    })
                    
                    CloudData.instance.getBuildingById(userId: user_id, buildingId: building_id, completion: { (building) in
                        self.title = building.buildingName as String
                        self.roomsCollection.reloadData()
                    })
                }
            }
        })
        
        // User is signed in.
        self.getRooms()
    }
    
    // Actions
    
    @IBAction func unwindToRoomsVC(segue:UIStoryboardSegue) {

    }

    
    @IBAction func addRoomPressed(_ sender: Any) {

    }
    
    @IBAction func editBuildingPressed(_ sender: Any) {

    }

    
    
}
