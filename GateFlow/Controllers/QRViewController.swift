import QRCodeGenerator
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import CoreImage
import Firebase

class QRViewController: UIViewController {

    @IBOutlet weak var QRCode: UIImageView!
    @IBOutlet weak var welcomeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Subscribe to screenshot notification
        NotificationCenter.default.addObserver(self, selector: #selector(userDidTakeScreenshot), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        
        // Check if user is already authenticated
        if let currentUser = Auth.auth().currentUser {
            fetchQRCodeForCurrentUser()
            fetchUsernameForCurrentUser()
        } else {
            promptUserToLogin()
        }
    }

    // Method triggered when a screenshot is taken
    @objc func userDidTakeScreenshot() {
        print("Screenshot detected!")
        // Block the user in Firestore
        blockUserForScreenshot()
    }
    
    // Function to block the user in Firestore
    func blockUserForScreenshot() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is logged in")
            return
        }
        
        let userId = currentUser.uid  // Get the user's UID
        let db = Firestore.firestore()
        
        // Update the user's status to "blocked" in Firestore
        db.collection("users").document(userId).updateData([
            "approvalStatus": "blocked"
        ]) { error in
            if let error = error {
                print("Error updating user status: \(error.localizedDescription)")
            } else {
                print("User has been blocked for taking a screenshot.")
                self.showBlockedMessageAndLogout()
            }
        }
    }
    
    // Show a message and log the user out
    func showBlockedMessageAndLogout() {
        let alert = UIAlertController(title: "Blocked", message: "Screenshot detected. Your account has been blocked.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            // Log out the user
            self.logoutUser()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Log out the user
    func logoutUser() {
        do {
            try Auth.auth().signOut()
            // Redirect the user to the login screen or exit the app
            print("User logged out.")
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    deinit {
        // Remove the observer when the view controller is deallocated
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }

    // Function to prompt login for a user (you can customize this)
    func promptUserToLogin() {
        let alert = UIAlertController(title: "Login", message: "Enter your email and password", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Email"
        }
        
        alert.addTextField { (textField) in
            textField.isSecureTextEntry = true
            textField.placeholder = "Password"
        }
        
        let loginAction = UIAlertAction(title: "Login", style: .default) { _ in
            let email = alert.textFields?[0].text ?? ""
            let password = alert.textFields?[1].text ?? ""
            self.loginUser(email: email, password: password)
        }
        
        alert.addAction(loginAction)
        self.present(alert, animated: true, completion: nil)
    }

    // Login user function dynamically (any user)
    func loginUser(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error logging in: \(error.localizedDescription)")
            } else {
                print("Successfully logged in!")
                
                // Fetch QR code and username after successful login
                self.fetchQRCodeForCurrentUser()
                self.fetchUsernameForCurrentUser()
            }
        }
    }

    // Function to fetch the QR code for the currently authenticated user
    func fetchQRCodeForCurrentUser() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is logged in")
            return
        }

        let userId = currentUser.uid  // Get the user's UID
        fetchQRCodeFromFirestore(documentId: userId) { base64String in
            if let base64String = base64String {
                self.displayQRCodeInImageView(qrCodeImageView: self.QRCode, base64String: base64String)
            } else {
                print("Failed to fetch QR code from Firestore")
            }
        }
    }
    
    // Fetch username for the currently authenticated user
    func fetchUsernameForCurrentUser() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is logged in")
            return
        }

        let userId = currentUser.uid  // Get the user's UID
        let db = Firestore.firestore()

        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                if let username = document.get("name") as? String {
                    // Update the welcome label with the username
                    self.welcomeLabel.text = "Welcome, \(username)"
                } else {
                    print("Username not found")
                    self.welcomeLabel.text = "Welcome, User"
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    // Fetch QR code from Firestore using the authenticated user's UID
    func fetchQRCodeFromFirestore(documentId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").document(documentId).getDocument { (document, error) in
            if let document = document, document.exists {
                if let base64String = document.get("qrCode") as? String {
                    completion(base64String)
                } else {
                    completion(nil)
                }
            } else {
                print("Document does not exist")
                completion(nil)
            }
        }
    }

    // Decode Base64 string to Data
    func decodeBase64ToData(base64String: String) -> Data? {
        return Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)
    }

    // Convert Data to UIImage
    func convertDataToImage(data: Data) -> UIImage? {
        return UIImage(data: data)
    }

    // Display QR code in the UIImageView
    func displayQRCodeInImageView(qrCodeImageView: UIImageView, base64String: String) {
        if let data = decodeBase64ToData(base64String: base64String) {
            if let image = convertDataToImage(data: data) {
                qrCodeImageView.image = image
            } else {
                print("Failed to convert data to UIImage")
            }
        } else {
            print("Failed to decode Base64 string")
        }
    }
}
