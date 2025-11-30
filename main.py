import cv2
from pyzbar.pyzbar import decode


def scan_qr_code_from_camera():
    # Open the camera (camera index 0 is usually the default)
    cap = cv2.VideoCapture(0)
    cap.set(3, 640)  # Set width
    cap.set(4, 480)  # Set height

    print("Camera activated. Please show a QR code to scan.")

    while True:
        success, frame = cap.read()
        if not success:
            break

        # Scan for QR codes in the captured frame
        for barcode in decode(frame):
            qr_data = barcode.data.decode('utf-8')
            print(f"QR Code detected: {qr_data}")

            # Draw a polygon around the detected QR code
            points = barcode.polygon
            if len(points) == 4:
                pts = [(point.x, point.y) for point in points]
                cv2.polylines(frame, [np.array(pts)], True, (0, 255, 0), 3)

            # Show the frame with the detected QR code
            cv2.imshow("QR Code Scanner", frame)

            # Release resources and return the QR code data
            cap.release()
            cv2.destroyAllWindows()
            return qr_data

        # Display the frame even if no QR code is detected
        cv2.imshow("QR Code Scanner", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()
    return None

#
