//
//  UserDataService.swift
//  Roomly
//
//  Created by Jason Shultz on 11/22/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Foundation

class UserDataService {
    
    static let instance = UserDataService()
    
    public private(set) var id = ""
    public private(set) var email = ""
    public private(set) var token = ""
    
    func setUserData(id: String, email: String, token: String) {
        self.id = id
        self.email = email
        self.token = token
    }
    
    func logoutUser() {
        id = ""
        email = ""
    }
    
}
