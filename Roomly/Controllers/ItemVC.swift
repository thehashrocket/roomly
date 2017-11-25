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
    
    var ref: DatabaseReference!
    let selected_room = DataService.instance.getSelectedRoom()
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private(set) public var items = [Item]()
    
    // Outlets
    @IBOutlet weak var itemsCollection: UICollectionView!
    
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        itemsCollection.dataSource = self
        itemsCollection.delegate = self
        
        self.ref = Database.database().reference()

        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                // User is signed in.
                print("here")
                
                guard let userID = Auth.auth().currentUser?.uid else { return }
                
                self.ref.child("items").child(userID).child(self.selected_room as String).observe(DataEventType.value, with: { (snapshot) in
                    let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                    print("now here")
                    DataService.instance.resetItems()
                    
                    postDict.forEach({ (arg) in
                        let (_, value) = arg
                        let dataChange = value as! [String: AnyObject]
                        print(dataChange["itemName"]);
                        
                        let id = dataChange["id"] as! String
                        let itemName = dataChange["itemName"] as! String
                        let itemDescription = dataChange["itemDescription"] as! String
                        let imageName = dataChange["imageName"] as! String
                        let roomId = dataChange["roomId"] as! String
                        let uid = dataChange["uid"] as! String
                        
                        let item = Item(id: id, itemName: itemName, itemDescription: itemDescription, imageName: imageName, roomId: roomId, uid: uid)
                        
                        DataService.instance.setItem(item: item)
                        
                        self.items = DataService.instance.getItemsForRoom(forRoomId: self.selected_room)
                        
                        self.itemsCollection.reloadData()
                    })
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
    
    func initItems(room: Room) {
        items = DataService.instance.getItemsForRoom(forRoomId: room.id)
        navigationItem.title = room.roomName! as String
    }
    
    // Actions
    
    @IBAction func addItemPressed(_ sender: Any) {
        let addItem = AddItemVC()
        addItem.modalPresentationStyle = .custom
        present(addItem, animated: true, completion: nil)
    }
    
}
