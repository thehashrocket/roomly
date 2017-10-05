//
//  Room.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation

struct Room {
    private(set) public var title: String!
    private(set) public var imageName: String!
    private(set) public var items: Array<Item>
    
    init(title: String, imageName: String, items: Array<Item>) {
        self.title = title
        self.imageName = imageName
        self.items = items
    }
}
