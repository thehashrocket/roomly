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
    
    public private(set) var uid = ""
    public private(set) var email = ""
    public private(set) var token = ""
    
    func setUserData(uid: String, email: String, token: String) {
        self.uid = uid
        self.email = email
        self.token = token
    }
    
    func logoutUser() {
        uid = ""
        email = ""
        token = ""
    }
    
}
