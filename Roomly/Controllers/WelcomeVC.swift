//
//  WelcomeVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/11/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
//import FirebaseFacebookAuthUI
import FirebasePhoneAuthUI



class WelcomeVC: UIViewController, FUIAuthDelegate {
    
    // Variables
    var uid = ""
    var email = ""
    var token = ""
    
    // Outlets
    @IBOutlet weak var goHomeBtn: UIButton!
    @IBOutlet weak var logOutBtn: RoundedButton!
    @IBOutlet weak var loginBtn: RoundedButton!
    
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authUI: FUIAuth? //only set internally but get externally
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.auth = Auth.auth()
        self.authUI = FUIAuth.defaultAuthUI()
        self.authUI?.delegate = self
//        self.authUI?.providers = [FUIPhoneAuth(authUI: self.authUI!),]
        
        let barBtn = UIBarButtonItem()
        barBtn.title = ""
        navigationItem.backBarButtonItem = barBtn
        
        self.authStateListenerHandle = self.auth?.addStateDidChangeListener { (auth, user) in
            
            let user = Auth.auth().currentUser
            
            if user != nil {
                self.loginBtn.isHidden = true
                self.logOutBtn.isHidden = false
                self.goHomeBtn.isHidden = false
            } else {
                // No user is signed in.
                print("No user is signed in.")
                self.goHomeBtn.isHidden = true
                self.logOutBtn.isHidden = true
                self.loginBtn.isHidden = false
                self.loginAction(sender: self)
            }
        }
        
        if let user = Auth.auth().currentUser {
            user.getIDTokenForcingRefresh(true, completion: { (token, error) in
                if (token != nil) {
                    UserDataService.instance.setUserData(uid: (user.uid), email: (user.email!), token: token!)
                    // User is signed in.
                    self.loginBtn.isHidden = true
                    self.goHomeBtn.isHidden = false
                    self.logOutBtn.isHidden = false
                    print("user is signed in")
                }
                
                if let error = error {
                    print(error)
                }

                
            })
            
        } else {
            // No user is signed in.
            print("no user signed in.")
        }
    }
    // Actions
    @IBAction func loginBtnPressed(_ sender: Any) {
        loginAction(sender: "nil" as AnyObject)
    }
    
    @IBAction func goHome(_ sender: Any) {
        self.performSegue(withIdentifier: "roomlyVC", sender: self)
    }
    
    @IBAction func logOut(_ sender: Any) {
        do {
            try self.auth?.signOut()
        } catch {
            
        }
    }
    
    @IBAction func loginAction(sender: AnyObject) {
        // Present the default login view controller provided by authUI
        let authViewController = authUI?.authViewController();
        self.present(authViewController!, animated: true, completion: nil)
        
    }
    
    // Implement the required protocol method for FIRAuthUIDelegate
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        guard let authError = error else { return }
        
        let errorCode = UInt((authError as NSError).code)
        
        switch errorCode {
        case FUIAuthErrorCode.userCancelledSignIn.rawValue:
            print("User cancelled sign-in");
            break
            
        default:
            let detailedError = (authError as NSError).userInfo[NSUnderlyingErrorKey] ?? authError
            print("Login error: \((detailedError as! NSError).localizedDescription)");
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func loginPressed(_ sender: Any) {
        performSegue(withIdentifier: "loginVC", sender: nil)
    }
    
}


