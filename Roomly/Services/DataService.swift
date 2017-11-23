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
        Building(id: "1", buildingName: "House 1", street: "street 1", city: "cityName", state: "stateName", zip: "55555", uid: "123456", imageName: "house1.png"),
        Building(id: "1", buildingName: "House 2", street: "street 1", city: "cityName", state: "stateName", zip: "55555", uid: "123456", imageName: "house2.png"),
        Building(id: "1", buildingName: "House 3", street: "street 1", city: "cityName", state: "stateName", zip: "55555", uid: "123456", imageName: "house3.png"),
    ]
    
    private let rooms = [
        Room(id: "1", title: "Bedroom 1", imageName: "bedroom1.jpg", buildingId: "1", items: []),
        Room(id: "2", title: "Living Room 2", imageName: "livingroom1.jpg", buildingId: "1", items: []),
        Room(id: "3", title: "Bathroom 3", imageName: "bathroom1.jpg", buildingId: "1", items: []),
        Room(id: "3", title: "Bedroom 1", imageName: "bedroom2.jpg", buildingId: "2", items: []),
        Room(id: "4", title: "Living Room 2", imageName: "livingroom2.jpg", buildingId: "2", items: []),
        Room(id: "5", title: "Bathroom 3", imageName: "bathroom2.jpg", buildingId: "2", items: []),
        Room(id: "6", title: "Bedroom 1", imageName: "bedroom3.jpg", buildingId: "3", items: []),
        Room(id: "7", title: "Living Room 2", imageName: "livingroom3.jpg", buildingId: "3", items: []),
        Room(id: "8", title: "Bathroom 3", imageName: "bathroom3.jpg", buildingId: "3", items: [])
    ]
    
    func getBuildings() -> [Building] {
        return buildings
    }
    
    func getRooms(forBuildingId buildingID: String) -> [Room] {
        return rooms.filter({ $0.buildingId == buildingID})
    }
}
