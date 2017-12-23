//
//  NewUserVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/27/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//

import Firebase

class NewUserVC: UIViewController {
    
    // Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Actions
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func createAccountPressed(_ sender: Any) {
        spinner.startAnimating()
        guard let email = emailTextField.text, emailTextField.text != "" else {return}
        guard let password = passwordTextField.text, passwordTextField.text != "" else {return}
        guard let confirmPassword = confirmPasswordTextField.text, confirmPasswordTextField.text != "" else {return}
        
        if password == confirmPassword {
            Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                
                if (user != nil) {
                    self.performSegue(withIdentifier: "BuildingsVC", sender: self)
                }
                
                if (error != nil) {
                    self.errorLabel.text = error?.localizedDescription
                }
            })
        } else {
            self.errorLabel.text = "Passwords did not match. Please try again."
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
