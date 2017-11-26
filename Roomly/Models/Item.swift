//
//  Item.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation

struct Item {
    private(set) public var id: NSString!
    private(set) public var itemName: NSString!
    private(set) public var itemDescription: NSString!
    private(set) public var imageName: NSString!
    private(set) public var purchaseAmount: NSString!
    private(set) public var purchaseDate: NSString!
    private(set) public var roomId: NSString!
    private(set) public var uid: NSString!
    
    
    init(id: String, itemName: String, itemDescription: String, imageName: String, purchaseAmount: String, purchaseDate: String, roomId: String, uid: String) {
        self.id = id as NSString
        self.itemName = itemName as NSString
        self.itemDescription = itemDescription as NSString
        self.imageName = imageName as NSString
        self.purchaseAmount = purchaseAmount as NSString
        self.purchaseDate = purchaseDate as NSString
        self.roomId = roomId as NSString
        self.uid = uid as NSString
    }
}
