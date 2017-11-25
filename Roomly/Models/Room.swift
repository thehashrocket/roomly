//
//  Room.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation

struct Room {
    private(set) public var id: NSString!
    private(set) public var roomName: NSString!
    private(set) public var roomDescription: NSString!
    private(set) public var imageName: NSString!
    private(set) public var buildingId: NSString!
    private(set) public var uid: NSString!
    
    init(id: NSString, roomName: String, roomDescription: String, imageName: String, buildingId: String, uid: String ) {
        self.id = id as NSString
        self.roomName = roomName as NSString
        self.roomDescription = roomDescription as NSString
        self.imageName = imageName as NSString
        self.buildingId = buildingId as NSString
        self.uid = uid as NSString
    }
}
