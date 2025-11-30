import UIKit
import CoreImage

class QRGenerator {
    func generateQRCode(from string: String, scale: CGFloat = 10) -> UIImage? {
        guard let data = string.data(using: String.Encoding.ascii) else { return nil }

        // Create the QR code filter
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("Q", forKey: "inputCorrectionLevel")  // Error correction level

            // Get the output image
            if let qrImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: scale, y: scale)  // Scale the image
                let scaledImage = qrImage.transformed(by: transform)
                return UIImage(ciImage: scaledImage)
            }
        }

        return nil
    }
}
