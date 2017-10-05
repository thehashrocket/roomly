//
//  HomeVC.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit

class HomeVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
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
    
    
    @IBOutlet weak var buildingTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        buildingTable.dataSource = self
        buildingTable.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

