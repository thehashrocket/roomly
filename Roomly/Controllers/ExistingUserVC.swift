//
//  ExistingUserVC.swift
//  Roomly
//
//  Created by Jason Shultz on 11/27/17.
//  Copyright © 2017 Chaos Elevators, Inc. All rights reserved.
//
import Firebase

class ExistingUserVC: UIViewController {
    
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
    
    override func viewWillAppear(_ animated: Bool) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    // Outlets
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    // Actions
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }
    
    @IBAction func submitBtnPressed(_ sender: Any) {
        self.spinner.startAnimating()
        guard let email = emailField.text, emailField.text != "" else {return}
        guard let password = passwordField.text, passwordField.text != "" else {return}
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            
            self.spinner.stopAnimating()
            if (user != nil) {
                self.errorLabel.text = user?.email
                self.performSegue(withIdentifier: "BuildingsVC", sender: nil)
            }
            
            if (error != nil) {
                self.errorLabel.text = error?.localizedDescription
            }
        }
    }
    
    @IBAction func resetPasswordPressed(_ sender: Any) {
        guard let email = emailField.text, emailField.text != "" else {return}
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            
            if (error != nil) {
                self.errorLabel.text = error?.localizedDescription
            }
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
