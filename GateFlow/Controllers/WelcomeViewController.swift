import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = ""
        let homeText = "GateFlow"
        var charIndex = 0.0

        // Creating an effect for homeText
        for letter in homeText {
            Timer.scheduledTimer(withTimeInterval: 0.2 * charIndex, repeats: false) { timer in
                self.titleLabel.text?.append(letter)
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.titleLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }) { _ in
                    UIView.animate(withDuration: 0.1) {
                        self.titleLabel.transform = CGAffineTransform.identity
                    }
                }
                
                // Force layout update to ensure it stays centered
                self.titleLabel.layoutIfNeeded()
            }
            charIndex += 1
        }

       
    }
    

}
