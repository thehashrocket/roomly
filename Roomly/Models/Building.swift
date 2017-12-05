//
//  Building.swift
//  Roomly
//
//  Created by Jason Shultz on 10/4/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation

struct Building {
    private(set) public var id: NSString!
    private(set) public var buildingName: NSString!
    private(set) public var street: NSString!
    private(set) public var city: NSString!
    private(set) public var state: NSString!
    private(set) public var country: NSString!
    private(set) public var zip: NSString!
    private(set) public var uid: NSString!
    private(set) public var imageName: NSString!
    private(set) public var images: NSDictionary
    
    init(id: String, buildingName: String, street: String, city: String, state: String, country: String, zip: String, uid: String, imageName: String, images: NSDictionary) {
        self.id = id as NSString
        self.buildingName = buildingName as NSString
        self.city = city as NSString
        self.country = country as NSString
        self.state = state as NSString
        self.street = street as NSString
        self.uid = uid as NSString as NSString
        self.zip = zip as NSString
        self.imageName = imageName as NSString
        self.images = images as NSDictionary
    }
}
