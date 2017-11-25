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
    
    private var buildings = [
        Building(id: "1", buildingName: "House 1", street: "street 1", city: "cityName", state: "stateName", zip: "55555", uid: "123456", imageName: "house1.jpg"),
        Building(id: "1", buildingName: "House 2", street: "street 1", city: "cityName", state: "stateName", zip: "55555", uid: "123456", imageName: "house2.jpg"),
        Building(id: "1", buildingName: "House 3", street: "street 1", city: "cityName", state: "stateName", zip: "55555", uid: "123456", imageName: "house3.jpg"),
    ]
    
    private let rooms = [
        Room(id: "1", roomName: "Bedroom 1", roomDescription: "", imageName: "bedroom1.jpg", buildingId: "1", uid: "123456"),
        Room(id: "2", roomName: "Living Room 2", roomDescription: "", imageName: "livingroom1.jpg", buildingId: "1", uid: "123456"),
    ]
    
    private var selected_building = "" as NSString
    private var selected_room = "" as NSString
    
    func getBuildings() -> [Building] {
        return buildings
    }
    
    func getRooms(forBuildingId buildingID: NSString) -> [Room] {
        return rooms.filter({ $0.buildingId == buildingID})
    }
    
    func getSelectedBuilding() -> NSString {
        return selected_building
    }
    
    func getSelectedRoom() -> NSString {
        return selected_room
    }
    
    func resetBuildings() {
        buildings = []
    }
    
    func setBuilding(building: Building) {
        buildings.append(building)
    }
    
    func setSelectedBuilding(building: Building) {
        selected_building = building.id
    }
    
    func setSelectedRoom(room: Room) {
        selected_room = room.uid
    }
}
