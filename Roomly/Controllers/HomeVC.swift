//
//  HomeVC.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class HomeVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildingTable.dataSource = self
        buildingTable.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBOutlet weak var buildingTable: UITableView!

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataService.instance.getBuildings().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BuildingCell") as? BuildingCell {
            let building = DataService.instance.getBuildings()[indexPath.row]
            cell.updateViews(building: building)
            return cell
        } else {
            return BuildingCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let building = DataService.instance.getBuildings()[indexPath.row]
        performSegue(withIdentifier: "RoomVC", sender: building)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("in segue")
        if let roomVC = segue.destination as? RoomVC {
            print (sender)
            assert(sender as? Building != nil)
            roomVC.initRooms(building: sender as! Building)
        }
    }


}

