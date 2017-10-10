//
//  Building.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation

struct Building {
    private(set) public var id: String!
    private(set) public var title: String!
    private(set) public var imageName: String!
    private(set) public var rooms: Array<Room>
    
    init(id: String, title: String, imageName: String, rooms: Array<Room>) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.rooms = rooms
    }
}
