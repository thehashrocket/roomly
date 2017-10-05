//
//  DataService.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation

class DataService {
    static let instance = DataService()
    
    private let buildings = [
        Building(title: "House 1", imageName: "house1.png", rooms: []),
        Building(title: "House 2", imageName: "house2.png", rooms: []),
        Building(title: "House 3", imageName: "house3.png", rooms: []),
    ]
    
    func getBuildings() -> [Building] {
        return buildings
    }
}
