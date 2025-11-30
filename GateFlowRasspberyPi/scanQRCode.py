#OLD VERSION
import cv2
import numpy as np

def face_recognition(model, captured_face, registered_faces):
    # Convert the captured face to grayscale
    captured_face_gray = cv2.cvtColor(captured_face, cv2.COLOR_BGR2GRAY)

    # Assume registered_faces is a dictionary containing the registered images (already in grayscale)
    # mapped to user IDs
    min_distance = float('inf')
    recognized_id = None

    # Iterate over all registered faces and check for a match
    for face_id, reg_face in registered_faces.items():
        # The model returns a label and a distance (confidence) for the current face
        label, distance = model.predict(reg_face)
        print(f"Testing against face_id={face_id}, Label={label}, Distance={distance}")

        # Keep the label with the minimum distance
        if distance < min_distance:
            min_distance = distance
            recognized_id = face_id

    # Assume a threshold for similarity
    if min_distance < 100:  # Similarity threshold, adjust based on experimentation
        print(f"Face recognized with ID={recognized_id} and distance={min_distance}")
        return recognized_id
    else:
        print("No matching face found.")
        return None

# Create and load a pre-trained model
model = cv2.face.LBPHFaceRecognizer_create()
model.read('path_to_pretrained_model.xml')  # Path to your pre-trained model

# Usage of the function
# captured_face - the image captured in real-time
# registered_faces - a dictionary of user's saved images {user_id: image, ...}
recognized_user_id = face_recognition(model, captured_face, registered_faces)
