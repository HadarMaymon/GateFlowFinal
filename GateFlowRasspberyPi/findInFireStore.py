import firebase_admin
from firebase_admin import credentials, firestore

class FindInFireStore:
    def __init__(self):
        if not firebase_admin._apps:  # Check if Firebase is already initialized
            cred = credentials.Certificate('/home/pi/Desktop/ProjectGateFlow2/gateflow-2ddb0-firebase-adminsdk-aev5z-90566db424.json')
            firebase_admin.initialize_app(cred)
        self.db = firestore.client()

    def check_approval_status(self, input_str):
        """
        Removes the 'userID:' prefix from the input, retrieves the document from Firestore,
        and checks the approval status of a user.
        """
        doc_id = input_str.replace("userID:", "").strip() if input_str.startswith("userID:") else input_str
        doc_ref = self.db.collection('users').document(doc_id)
        
        try:
            doc = doc_ref.get()
            if doc.exists:
                user_data = doc.to_dict()
                approval_status = user_data.get('approvalStatus')
                if approval_status == 'approved':
                    print("User is approved.")
                    return True
                else:
                    print(f"User is not approved. Status: {approval_status}")
                    return False
            else:
                print(f"No user found with the given document ID: {doc_id}")
                return False
        except Exception as e:
            print(f"Error retrieving document: {e}")
            return False
