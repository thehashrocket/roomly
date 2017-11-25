//
//  RoomVC.swift
//  Roomly
//
//  Created by Jason Shultz on 10/9/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class RoomVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var roomsCollection: UICollectionView!
    
    private(set) public var rooms = [Room]()
    
    var selected_building = "" as NSString
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        roomsCollection.dataSource = self
        roomsCollection.delegate = self
        selected_building = DataService.instance.getSelectedBuilding()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func initRooms(building: Building) {
        rooms = DataService.instance.getRooms(forBuildingId: building.id as NSString)
        navigationItem.title = building.buildingName! as String
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
    
    // Actions
    @IBAction func addRoomPressed(_ sender: Any) {
        let addRoom = AddRoomVC()
        addRoom.modalPresentationStyle = .custom
        present(addRoom, animated: true, completion: nil)
    }
    
    @IBAction func editBuildingPressed(_ sender: Any) {
    }
    

}
