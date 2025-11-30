// MediaManager.swift
// GateFlow
// Created by Hadar Maymon on 08/12/2024.
// Copyright © 2024 Ofir. All rights reserved.

import UIKit
import AVFoundation
import MobileCoreServices

class MediaManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate {
    static let shared = MediaManager()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioRecordingCompletion: ((URL?) -> Void)?
    private var imageSelectionCompletion: ((UIImage?) -> Void)?
    private(set) var isRecording = false
    private(set) var recordedAudioURL: URL?
    
    // MARK: - Present Camera or Gallery Options
    func presentImagePickerOptions(from viewController: UIViewController, completion: @escaping (UIImage?) -> Void) {
        self.imageSelectionCompletion = completion

        let alert = UIAlertController(title: "Select Image", message: "Choose an option to select your photo.", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Capture Photo", style: .default) { _ in
            self.checkCameraAuthorization(from: viewController)
        })

        alert.addAction(UIAlertAction(title: "Choose from Gallery", style: .default) { _ in
            self.presentGallery(from: viewController)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        viewController.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Camera Authorization
    func checkCameraAuthorization(from viewController: UIViewController) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.presentCamera(from: viewController)
                    } else {
                        self.showPermissionAlert(from: viewController, message: "Camera access is required.")
                    }
                }
            }
        case .authorized:
            presentCamera(from: viewController)
        case .denied, .restricted:
            showPermissionAlert(from: viewController, message: "Camera access is denied.")
        @unknown default:
            showPermissionAlert(from: viewController, message: "An unknown error occurred.")
        }
    }

    // MARK: - Present Camera
    private func presentCamera(from viewController: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showPermissionAlert(from: viewController, message: "Camera is not available on this device.")
            return
        }
        print("Presenting camera...")
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        viewController.present(picker, animated: true) {
            print("Camera presented successfully.")
        }
    }
    
    // MARK: - Present Gallery
    private func presentGallery(from viewController: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            self.showPermissionAlert(from: viewController, message: "Gallery is not available.")
            return
        }
        print("Presenting gallery...")
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
        viewController.present(picker, animated: true) {
            print("Gallery presented successfully.")
        }
    }
    
    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        
        // Save image to documents directory for persistence
        if let imageData = image?.jpegData(compressionQuality: 0.8) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let photoURL = documentsPath.appendingPathComponent(UUID().uuidString + ".jpg")
            
            do {
                try imageData.write(to: photoURL, options: .atomic)
                print("Photo successfully saved to: \(photoURL.path)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if FileManager.default.fileExists(atPath: photoURL.path) {
                        print("File verified at: \(photoURL.path)")
                        self.imageSelectionCompletion?(UIImage(contentsOfFile: photoURL.path))
                    } else {
                        print("Failed to verify photo at path: \(photoURL.path)")
                        self.imageSelectionCompletion?(nil)
                    }
                }
            } catch {
                print("Failed to save photo: \(error.localizedDescription)")
                self.imageSelectionCompletion?(nil)
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    // MARK: - Start Audio Recording
    func startRecording(completion: @escaping (URL?) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let audioFileURL = documentsPath.appendingPathComponent(UUID().uuidString + "_voiceRecording.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            self.audioRecordingCompletion = completion
            self.recordedAudioURL = audioFileURL
            self.isRecording = true
            
            print("✅ Recording started at: \(audioFileURL.path)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
                guard let self = self else { return }
                if self.isRecording {
                    self.stopRecording()
                    if FileManager.default.fileExists(atPath: audioFileURL.path) {
                        print("✅ Audio file exists after recording: \(audioFileURL.path)")
                    } else {
                        print("❌ Audio file does NOT exist after recording!")
                    }
                    completion(self.recordedAudioURL)
                }
            }
        } catch {
            print("❌ Recording failed: \(error.localizedDescription)")
            self.recordedAudioURL = nil
            completion(nil)
        }
    }


    // MARK: - Stop Audio Recording
    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.stop()
        audioRecorder = nil
        isRecording = false
        print("Recording stopped.")
        
        if let completion = self.audioRecordingCompletion {
            completion(self.recordedAudioURL)
            self.audioRecordingCompletion = nil // Clear the completion handler to avoid duplicate calls
        }
    }
    
    // MARK: - Check Microphone Permission
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
            print("Microphone access denied.")
        case .undetermined:
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    // MARK: - Permission Alert
    func showPermissionAlert(from viewController: UIViewController, message: String) {
        let alert = UIAlertController(title: "Permission Needed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true, completion: nil)
    }
}
