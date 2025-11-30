from deepface import DeepFace
import os
import cv2
import traceback

class scanFace:
    @staticmethod
    def match_faces_average(image_folder, test_image_path, target_images, model_name="ArcFace", enforce_detection=False):
        results = {}
        verified_values = []  # This list will store 1 for True, 0 for False for each target image.
        
        # Check if the test image can be loaded using OpenCV
        test_img = cv2.imread(test_image_path)
        if test_img is None:
            error_msg = f"Cannot load test image from {test_image_path}"
            print(f"Error: {error_msg}")
            return False, 0.0, {"error": error_msg}
        
        for target_img in target_images:
            target_path = os.path.join(image_folder, target_img)
            print(f"Processing target image: {target_path}")
            
            # Check if the target image can be loaded using OpenCV
            target_cv2 = cv2.imread(target_path)
            if target_cv2 is None:
                error_msg = f"Cannot load target image from {target_path}"
                results[target_img] = {"error": error_msg}
                print(f"Error: {error_msg}")
                verified_values.append(0)
                continue
            
            try:
                # Call DeepFace.verify with enforce_detection parameter
                verification = DeepFace.verify(
                    img1_path=target_path, 
                    img2_path=test_image_path, 
                    model_name=model_name, 
                    enforce_detection=enforce_detection
                )
                verified = verification.get("verified", False)
                results[target_img] = {"verified": verified}
                print(f"Result for {target_img}: {results[target_img]}")
                verified_values.append(1 if verified else 0)
            except Exception as e:
                error_details = traceback.format_exc()
                results[target_img] = {"error": error_details}
                print(f"Exception processing {target_img}: {error_details}")
                verified_values.append(0)
        
        # Calculate the average of the verified values
        if verified_values:
            average_verified = sum(verified_values) / len(verified_values)
        else:
            average_verified = 0.0
        
        overall_match = average_verified >= 0.5
        
        print(f"Average verification: {average_verified}")
        print(f"Overall match: {overall_match}")
        return overall_match, average_verified, results
