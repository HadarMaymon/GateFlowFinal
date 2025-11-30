import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var showPasswordLoginButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate of your text fields
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }

    
    @IBAction func loginPressed(_ sender: UIButton) {
        if let email = emailTextField.text, let password = passwordTextField.text {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.messageLabel.text = "Login error: \(error.localizedDescription)"
                    return
                }

                if let user = authResult?.user {
                    let db = Firestore.firestore()
                    let userRef = db.collection("users").document(user.uid)

                    userRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            let data = document.data()
                            let approvalStatus = data?["approvalStatus"] as? String ?? "pending"
                            if approvalStatus == "approved" {
                                // Proceed to the app screen
                                self.performSegue(withIdentifier: "goToApp", sender: self)
                            } else if approvalStatus == "pending" {
                                self.messageLabel.text = "Account has yet to be verified"
                            } else if approvalStatus == "rejected" {
                                self.messageLabel.text = "Account has been rejected"
                            }
                            else if approvalStatus == "blocked" {
                                self.messageLabel.text = "Account has been blocked due security reasons, please contact admin."
                            }
                        } else {
                            self.messageLabel.text = "User data not found"
                        }
                    }
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  // This dismisses the keyboard
        return true
    }
    
    
    
    @IBAction func clickedShowPasswordLogin(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        
        // Change the button's image based on the current state
        if passwordTextField.isSecureTextEntry {
            showPasswordLoginButton.setImage(UIImage(named: "eye.slash.fill"), for: .normal)
        } else {
            showPasswordLoginButton.setImage(UIImage(named: "eye.slash.fill"), for: .normal)
        }
    }

}
