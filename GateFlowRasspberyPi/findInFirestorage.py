import os
import firebase_admin
from firebase_admin import credentials, storage

class FindInFireStorage:
    def __init__(self):
        if not firebase_admin._apps:  # Check if Firebase is already initialized
            cred = credentials.Certificate('/home/pi/Desktop/ProjectGateFlow2/gateflow-2ddb0-firebase-adminsdk-aev5z-90566db424.json')
            firebase_admin.initialize_app(cred, {
                'storageBucket': 'gateflow-2ddb0.firebasestorage.app'
            })
        self.bucket = storage.bucket(name = 'gateflow-2ddb0.firebasestorage.app')

    def ensure_directory_exists(self, file_path):
        """
        Creates a directory if it does not exist.
        """
        directory = os.path.dirname(file_path)
        if not os.path.exists(directory):
            os.makedirs(directory)

    def manage_files(self, user_id, file_type):
        """
        Downloads image or audio files from Firebase Storage.
        """
        file_paths = {
            'photos': '/home/pi/Desktop/ProjectGateFlow2/photos',
            'audio': '/home/pi/Desktop/ProjectGateFlow2/Audio/fireStorageAudio'
        }
        file_path = file_paths[file_type]

        file_prefix = f'users/{user_id}/{file_type}'  # Removed trailing slash
        print(f"? Searching for files in Firebase Storage with prefix: {file_prefix}")

        blobs = self.bucket.list_blobs(prefix=file_prefix)

        found_files = False
        for blob in blobs:
            found_files = True
            local_file_path = os.path.join(file_path, blob.name.split('/')[-1])
            self.ensure_directory_exists(local_file_path)
            blob.download_to_filename(local_file_path)
            print(f'? File {blob.name} downloaded to {local_file_path}.')

        if not found_files:
            print(f"? No files found in Firebase Storage under prefix: {file_prefix}")
