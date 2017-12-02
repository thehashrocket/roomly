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
    
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    // Outlets
    @IBOutlet weak var roomsCollection: UICollectionView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var houseImage: UIImageView!
    
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
        roomsCollection.dataSource = self
        roomsCollection.delegate = self
//        rooms = DataService.instance.getRooms()
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                guard let userID = Auth.auth().currentUser?.uid else { return }
                
                self.ref.child("buildings").child(userID).child(self.selected_building as String).observe(DataEventType.value, with: { (snapshot) in
                    
                    let value = snapshot.value as? NSDictionary
                    
                    if ((value) != nil) {
                        let building_id = value?["id"] as! String
                        let saved_image = value?["imageName"] as! String
                        let user_id = userID as! String
                        let destination = "buildings/\(user_id)/\(building_id)/"
                        
                        CloudStorage.instance.loadTopImage(destination: destination, saved_image: saved_image, completion: { (image) in
                            self.houseImage.image = image
                        })
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
        print("building.id \(building.id)")
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
    
    func getRooms() {
        self.ref = Database.database().reference()
        guard let userID = Auth.auth().currentUser?.uid else { return }
        print("self.selected_building \(self.selected_building)")
        self.ref.child("rooms").child(userID).child(self.selected_building as String).observe(DataEventType.value, with: { (snapshot) in
            self.spinner.startAnimating()
            let postDict = snapshot.value as? [String : AnyObject] ?? [:]
            DataService.instance.resetRooms()
            
            postDict.forEach({ (arg) in
                let (_, value) = arg
                let dataChange = value as! [String: AnyObject]
                
                let id = dataChange["id"] as! String
                let roomName = dataChange["roomName"] as! String
                let roomDescription = dataChange["roomDescription"] as! String
                let imageName = dataChange["imageName"] as! String
                let buildingId = dataChange["buildingId"] as! String
                let uid = dataChange["uid"] as! String
                let room = Room(id: id, roomName: roomName, roomDescription: roomDescription, imageName: imageName, buildingId: buildingId, uid: uid)
                
                DataService.instance.setRoom(room: room)
                self.rooms = DataService.instance.getRoomsForBuilding(forBuildingId: self.selected_building)
                self.roomsCollection.reloadData()
                self.spinner.stopAnimating()
            })
        }, withCancel: { (error) in
            print("getRooms: ")
            print(error)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let itemVC = segue.destination as? ItemVC {
            let barBtn = UIBarButtonItem()
            barBtn.title = ""
            navigationItem.backBarButtonItem = barBtn
            assert(sender as? Room != nil)
            itemVC.initItems(room: sender as! Room)
        }
    }
    
    // Actions
    @IBAction func addRoomPressed(_ sender: Any) {
        let addRoom = AddRoomVC()
        addRoom.modalPresentationStyle = .custom
        present(addRoom, animated: true, completion: nil)
    }
    
    @IBAction func editBuildingPressed(_ sender: Any) {
        let editBuilding = EditBuildingVC()
        editBuilding.modalPresentationStyle = .custom
        present(editBuilding, animated: true, completion: nil)
    }

}
