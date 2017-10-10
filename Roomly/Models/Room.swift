//
//  Room.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation

struct Room {
    private(set) public var id: String!
    private(set) public var title: String!
    private(set) public var imageName: String!
    private(set) public var buildingId: String!
    private(set) public var items: Array<Item>
    
    init(id: String, title: String, imageName: String, buildingId: String, items: Array<Item>) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.buildingId = buildingId
        self.items = items
    }
}
