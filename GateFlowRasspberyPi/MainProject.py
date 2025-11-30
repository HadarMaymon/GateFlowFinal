import cv2
import os
from picamera2 import Picamera2
from gpiozero import Button, LED
from findInFireStore import FindInFireStore
from mainMotor import accountApproval
from time import sleep
from findInFirestorage import FindInFireStorage
from audioToNumbers import audioToNumbers
from record import record
from scanAudio import scanAudio
from scanFace import scanFace

# Initialize Picamera2
picam2 = Picamera2()

# Initialize button and LED
button = Button(26)
led1 = LED(4)

# Initialize Firebase access
firebase_checker = FindInFireStore()
firstorage_checker = FindInFireStorage()

# Path definitions
save_image_path = "/home/pi/Desktop/ProjectGateFlow2/new_image.jpg"  
save_audio_path = "/home/pi/Desktop/ProjectGateFlow2/Audio/audio_recording_for_check.m4a"

# Start the camera
picam2.start()

while True:
    # Capture a frame from the camera for live preview
    frame = picam2.capture_array()

    # Display the frame as live feed
    cv2.imshow("Live Camera Preview", frame)

    # Wait for button press to capture an image
    if button.is_pressed:
        led1.on()
        print("Button pressed, capturing image and recording sound...")

        # Save the captured frame to the defined save path
        cv2.imwrite(save_image_path, frame)
        print(f"Image saved to {save_image_path}")

        # Record audio from the microphone using record class
        record.record_sound()
        print(f"Audio recorded to {save_audio_path}")

        # Convert recorded audio to number string
        audio_processor = audioToNumbers()
        number_string = audio_processor.transcribe_audio(save_audio_path)
        print(f"Processed audio to number string: {number_string}")

        # Download user data (photos & audio) from Firebase Storage
        firstorage_checker.manage_files(number_string, 'photos')  # Get photos
        firstorage_checker.manage_files(number_string, 'audio')   # Get audio

        # Get user's saved audio file (assume first audio file found is valid)
        user_audio_dir = "/home/pi/Desktop/ProjectGateFlow2/Audio/fireStorageAudio"
        user_audio_files = [f for f in os.listdir(user_audio_dir) if f.endswith('.m4a')]
        if not user_audio_files:
            print("No audio file found for this user. Audio authentication failed. Access denied.")
            led1.off()
            continue
        
        user_audio_file = os.path.join(user_audio_dir, user_audio_files[0])

        # Compare captured audio with stored audio
        print("Starting audio verification...")
        if not scanAudio.compare_speakers(save_audio_path, user_audio_file):
            print("Audio verification failed. Access denied.")
            led1.off()
            continue
        else:
            print("Audio verification passed.")

        # Get user's saved photos (assume multiple images can exist)
        user_photos_dir = "/home/pi/Desktop/ProjectGateFlow2/photos"
        user_photo_files = [f for f in os.listdir(user_photos_dir) if f.endswith(('.jpg', '.png'))]

        if not user_photo_files:
            print("No photo found for this user. Face authentication failed. Access denied.")
            led1.off()
            continue

        # Compare captured image with stored images and get the average verification result
        print("Starting face verification...")
        overall_match, average_verified, face_details = scanFace.match_faces_average(
            user_photos_dir, "/home/pi/Desktop/ProjectGateFlow2/new_imageRan.jpg", user_photo_files, model_name="ArcFace", enforce_detection=False
        )
        print(f"Average verification: {average_verified}")
        print(f"Overall match: {overall_match}")
        if not overall_match:
            print("Face verification failed. Access denied.")
            print("Face verification details:", face_details)
            led1.off()
            continue
        else:
            print("Face verification passed.")

        # Both audio and face verifications passed; now check approval status
        print("Starting approval verification...")
        if firebase_checker.check_approval_status("userID:" + number_string):
            accountApproval()  # Open the door (run motor)
            print("User is approved, door opening.")
        else:
            print("Approval verification failed. Access denied.")
            led1.off()
            continue

        # Turn off the LED after processing
        led1.off()

    # Press 'q' to exit the loop and close the program
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Clean up
picam2.close()
cv2.destroyAllWindows()
