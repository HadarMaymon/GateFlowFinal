import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class RegisterViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var IDTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!
    @IBOutlet weak var showPasswordRegister: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var photoCountLabel: UILabel!
    
    // MARK: - Properties
    private var photoURLs: [URL] = []
    private var audioFileURL: URL?
    private let requiredPhotoCount = 3
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraButton.setTitle("", for: .normal)
        microphoneButton.setTitle("", for: .normal)

        nameTextField.delegate = self
        emailTextfield.delegate = self
        IDTextField.delegate = self
        PasswordTextField.delegate = self
        
        photoCountLabel.text = "0 of \(requiredPhotoCount) Photos Uploaded"
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

    }


    // MARK: - Dismiss Keyboard Methods

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // Dismiss keyboard when pressing "Return"
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // Dismiss keyboard when tapping outside
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }


    // MARK: - Camera Functionality
    @IBAction func cameraButtonPressed(_ sender: UIButton) {
        if photoURLs.count >= requiredPhotoCount {
            print("Maximum of \(requiredPhotoCount) photos reached.")
            return
        }

        MediaManager.shared.presentImagePickerOptions(from: self) { [weak self] selectedImage in
            guard let self = self, let image = selectedImage else { return }
            
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let photoURL = self.saveImageLocally(imageData: imageData)
                if let photoURL = photoURL {
                    self.photoURLs.append(photoURL)
                    DispatchQueue.main.async {
                        self.photoCountLabel.text = "\(self.photoURLs.count) of \(self.requiredPhotoCount) Photos Uploaded"
                        if self.photoURLs.count == self.requiredPhotoCount {
                            self.photoCountLabel.textColor = .systemGreen
                        }
                    }
                }
            }
        }
    }

    private func saveImageLocally(imageData: Data) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let photoURL = documentsPath.appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try imageData.write(to: photoURL, options: .atomic)
            print("Photo saved to: \(photoURL.path)")
            return photoURL
        } catch {
            print("Failed to save photo locally: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Microphone Functionality
    @IBAction func MicroButtonPressed(_ sender: UIButton) {
        MediaManager.shared.checkMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                if MediaManager.shared.isRecording {
                    MediaManager.shared.stopRecording()
                    self.updateMicrophoneButton(sender, isRecording: false)
                    self.audioFileURL = MediaManager.shared.recordedAudioURL
                } else {
                    MediaManager.shared.startRecording { [weak self] audioURL in
                        self?.audioFileURL = audioURL
                    }
                    self.updateMicrophoneButton(sender, isRecording: true)
                }
            } else {
                MediaManager.shared.showPermissionAlert(from: self, message: "Microphone permission is required.")
            }
        }
    }

    private func updateMicrophoneButton(_ button: UIButton, isRecording: Bool) {
        button.layer.borderColor = isRecording ? UIColor.red.cgColor : UIColor.clear.cgColor
        button.layer.borderWidth = isRecording ? 2.0 : 0.0
    }

    // MARK: - File Upload with Retry Logic
    private func uploadFileWithRetries(localURL: URL, storagePath: String, retryCount: Int = 3, completion: @escaping (URL?) -> Void) {
        guard retryCount > 0 else {
            print("Upload failed after maximum retries for: \(localURL.path)")
            completion(nil)
            return
        }

        guard FileManager.default.fileExists(atPath: localURL.path) else {
            print("Error: File does not exist at \(localURL.path)")
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child(storagePath)
        print("Uploading file: \(localURL.path) to Firebase path: \(storageRef.fullPath)")

        storageRef.putFile(from: localURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading file: \(error.localizedDescription). Retrying...")
                self.uploadFileWithRetries(localURL: localURL, storagePath: storagePath, retryCount: retryCount - 1, completion: completion)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error retrieving download URL: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    print("File uploaded successfully: \(url?.absoluteString ?? "")")
                    completion(url)
                }
            }
        }
    }

    // MARK: - Registration
    @IBAction func registerPressed(_ sender: UIButton) {
        guard photoURLs.count == requiredPhotoCount, let audioURL = audioFileURL else {
            messageLabel.text = "Please upload 3 photos and record audio before registering."
            return
        }

        guard let email = emailTextfield.text,
              let name = nameTextField.text,
              let password = PasswordTextField.text,
              let id = IDTextField.text,   // User-entered ID will be used as the document ID
              !email.isEmpty, !name.isEmpty, !password.isEmpty, !id.isEmpty else {
            messageLabel.text = "Please fill in all fields."
            return
        }

        messageLabel.text = "Uploading files..."
        let storageFolder = "users/\(id)"  // Folder named after the user's ID

        let dispatchGroup = DispatchGroup()
        var uploadedURLs: [URL] = []

        for (index, photoURL) in photoURLs.enumerated() {
            dispatchGroup.enter()
            let storagePath = "\(storageFolder)/photos/photo_\(index + 1).jpg"
            uploadFileWithRetries(localURL: photoURL, storagePath: storagePath) { url in
                if let url = url { uploadedURLs.append(url) }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.enter()
        let audioPath = "\(storageFolder)/audio/audio_recording.m4a"
        uploadFileWithRetries(localURL: audioURL, storagePath: audioPath) { url in
            if let url = url { uploadedURLs.append(url) }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            if uploadedURLs.count != self.photoURLs.count + 1 {
                self.messageLabel.text = "Some files failed to upload. Please try again."
                return
            }

            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.messageLabel.text = "Error creating user: \(error.localizedDescription)"
                    return
                }

                let db = Firestore.firestore()
                db.collection("users").document(id).setData([  // Use `id` as document ID
                    "name": name,
                    "email": email,
                    "id": id,  // Store the ID for consistency
                    "approvalStatus": "pending", // Hidden field in Firestore
                    "photos": uploadedURLs.prefix(3).map { $0.absoluteString },
                    "audio": uploadedURLs.last?.absoluteString ?? ""
                ]) { error in
                    if let error = error {
                        self.messageLabel.text = "Error saving user data: \(error.localizedDescription)"
                    } else {
                        self.messageLabel.text = "Registration complete!"
                        self.performSegue(withIdentifier: "goToLogin", sender: self)
                    }
                }
            }
        }
    }
}
