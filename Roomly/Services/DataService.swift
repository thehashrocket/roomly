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
}
