import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseAppCheck
import Firebase
import FirebaseStorage


@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        return true
    }
}

