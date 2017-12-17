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
    private(set) public var images: NSDictionary!
    private(set) public var buildingId: NSString!
    private(set) public var uid: NSString!
    
    init(id: String, roomName: String, roomDescription: String, imageName: String, images: NSDictionary, buildingId: String, uid: String ) {
        self.id = id as NSString
        self.roomName = roomName as NSString
        self.roomDescription = roomDescription as NSString
        self.imageName = imageName as NSString
        self.images = images as NSDictionary
        self.buildingId = buildingId as NSString
        self.uid = uid as NSString
    }
}
