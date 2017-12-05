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
    
    private var buildings = [Building]()
    
    private var rooms = [Room]()
    
    private var items = [Item]()
    
    private var selected_building = "" as NSString
    private var selected_item = "" as NSString
    private var selected_room = "" as NSString
    
    func getBuildings() -> [Building] {
        return buildings
    }
    
    func getItems() -> [Item] {
        return items
    }
    
    
    func getRooms() -> [Room] {
        return rooms
    }
    
    func getItemsForRoom(forRoomId roomId: NSString) -> [Item] {
        return items.filter({ $0.roomId == roomId})
    }
    
    func getRoomsForBuilding(forBuildingId buildingID: NSString) -> [Room] {
        return rooms.filter({ $0.buildingId == buildingID})
    }
    
    func getSelectedBuilding() -> NSString {
        return selected_building
    }
    
    func getSelectedRoom() -> NSString {
        return selected_room
    }
    
    func getSelectedItem() -> NSString {
        return selected_item
    }
    
    func resetBuildings() {
        buildings = []
    }
    
    func resetItems() {
        items = []
    }
    func resetRooms() {
        rooms = []
    }
    
    func setBuilding(building: Building) {
        buildings.append(building)
    }
    
    func setItem(item: Item) {
        items.append(item)
    }
    
    func setRoom(room: Room) {
        rooms.append(room)
    }
    
    func setSelectedBuilding(building: Building) {
        selected_building = building.id
    }
    
    func setSelectedItem(item: Item) {
        selected_item = item.id
    }
    
    func setSelectedRoom(room: Room) {
        selected_room = room.id
    }
    
    // filter worldData array by selected country.
    func filterWorldDataByCountry(data: [(city: String, country: String, state: String, geoId: String)], country: String) -> [String] {
        let filtered = data.filter { $0.country == country }
        let states = filtered.map({$0.2})
        let sortedStates = states.sorted(by: <)
        let reducedStates = DataService.instance.uniqueElementsFrom(array: sortedStates)
        return reducedStates
    }
    
    // filter worldData array by selected state.
    func filterWorldDataByState(data: [(city: String, country: String, state: String, geoId: String)], state: String) -> [String] {
        let filtered = data.filter { $0.state == state }
        let cities = filtered.map({$0.0})
        let sortedCities = cities.sorted(by: <)
        return sortedCities
    }
    
    func uniqueElementsFrom(array: [String]) -> [String] {
        //Create an empty Set to track unique items
        var set = Set<String>()
        let result = array.filter {
            guard !set.contains($0) else {
                //If the set already contains this object, return false
                //so we skip it
                return false
            }
            //Add this item to the set since it will now be in the array
            set.insert($0)
            //Return true so that filtered array will contain this item.
            return true
        }
        return result
    }
    
    func updateItem(new_item: Item) {
        
        if let index = items.index(where: { $0.id == new_item.id }) {
            items.remove(at: index)
            items.append(new_item)
        }
        
        items.forEach { (item) in
            print(item.itemName)
        }
    }
}
