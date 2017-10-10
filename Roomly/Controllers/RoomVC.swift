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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        roomsCollection.dataSource = self
        roomsCollection.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func initRooms(building: Building) {
        rooms = DataService.instance.getRooms(forBuildingId: building.id)
        navigationItem.title = building.title
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

}
