import UIKit
import PDFKit

public extension PDFPage {
    func getBackgroundColor() -> UIColor {
        let pageRect = self.bounds(for: .cropBox);
        let ratio = pageRect.width/pageRect.height;
        let thumbSize = CGSize.init(width: 256,height: Int(256/ratio));
        let image = self.thumbnail(of: thumbSize, for: .cropBox);
        return image.getPixelColor(CGPoint(x: 1, y: 1));
    }
}

extension UIImage {
    func getPixelColor(_ point: CGPoint) -> UIColor {
       guard let cgImage = self.cgImage else {
           return UIColor.clear
       }
       return cgImage.getPixelColor(point)
    }
}

extension CGImage {
    func getPixelColor(_ point: CGPoint) -> UIColor
    {
        // Create the bitmap context
        let width = Int(self.width);
        let height = Int(self.height);
        
        guard let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.stride) else {
            return UIColor.white;
        }
        defer {
            free(rawData);
        }

        let cgctx = CGContext.bitmapContext(for: rawData, width: width, height: height);
        guard let cgctx = cgctx else {
            return UIColor.white;
        }

        // Draw the image to the bitmap context. Once we draw, the memory
        // allocated for the context for rendering will then contain the
        // raw image data in the specified color space.
        cgctx.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Now we can get a pointer to the image data associated with the bitmap
        // context.
        let color = cgctx.readColorAt(x: Int(point.x), y: Int(point.y))
        return color;
    }
}

extension UIColor
{
    func blackOrWhiteContrastingColor() -> UIColor? {
        let black = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let white = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        let blackDiff = Float(luminosityDifference(black))
        let whiteDiff = Float(luminosityDifference(white))

        return (blackDiff > whiteDiff) ? black : white
    }

    private func luminosity() -> CGFloat {
        var red: CGFloat = 0;
        var green: CGFloat = 0;
        var blue: CGFloat = 0;
        var alpha: CGFloat = 0;

        var success = getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        if success {
            return 0.2126 * pow(red, 2.2) + 0.7152 * pow(green, 2.2) + 0.0722 * pow(blue, 2.2)
        }

        var white: CGFloat = 0;

        success = getWhite(&white, alpha: &alpha)
        if success {
            return pow(white, 2.2)
        }

        return -1
    }

    private func luminosityDifference(_ otherColor: UIColor?) -> CGFloat {
        let l1 = luminosity()
        let l2 = otherColor?.luminosity()

        if l1 >= 0 && (l2 ?? 0.0) >= 0 {
            if l1 > (l2 ?? 0.0) {
                return (l1 + 0.05) / ((l2 ?? 0.0) + 0.05)
            } else {
                return ((l2 ?? 0.0) + 0.05) / (l1 + 0.05)
            }
        }

        return 0.0
    }
}

extension CGContext {
    static func bitmapContext(for data: UnsafeMutableRawPointer,
                       width: Int,
                       height: Int) -> CGContext? {
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let cref = CGColorSpaceCreateDeviceRGB();

        let options = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext.init(data: data,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: bitsPerComponent,
                                           bytesPerRow: bytesPerRow,
                                           space: cref,
                                           bitmapInfo: options) else {
            return nil
        }
        return context
    }
    
    func readColorAt(x: Int, y: Int) -> UIColor {
        let capacity = self.width * self.height
        let widthMultiple = 8
        let rowOffset = ((self.width + widthMultiple - 1) / widthMultiple) * widthMultiple // Round up to multiple of 8
        guard let data = self.data?.bindMemory(to: UInt8.self, capacity: capacity) else {
            return UIColor.white
        }
        let offset = 4 * ((y * rowOffset) + x)

        let red = data[offset+2]
        let green = data[offset+1]
        let blue = data[offset]
        let alpha = data[offset+3]

        return UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: CGFloat(alpha)/255.0)
    }
}
