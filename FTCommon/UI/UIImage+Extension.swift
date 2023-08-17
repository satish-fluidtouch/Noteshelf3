//
//  File.swift
//  
//
//  Created by Narayana on 16/05/22.
//

import UIKit

public extension UIImage {
    func imageByScalingProportionallyToSize(_ targetSize: CGSize) -> UIImage! {
        return self.imageByScalingProportionallyToSize(targetSize, withCornerRadius: 0)
    }

    func imageByScalingProportionallyToSize(_ targetSize:CGSize, withCornerRadius radius:CGFloat) -> UIImage! {

        let sourceImage:UIImage! = self
        var newImage:UIImage! = nil

        let imageSize: CGSize = sourceImage.size
        let width: CGFloat = imageSize.width
        let height: CGFloat = imageSize.height

        let targetWidth: CGFloat = targetSize.width
        let targetHeight: CGFloat = targetSize.height

        var scaleFactor: CGFloat = 0.0
        var scaledWidth: CGFloat = targetWidth
        var scaledHeight: CGFloat = targetHeight

        var thumbnailPoint: CGPoint = CGPoint(x: 0.0,y: 0.0)

        if imageSize.equalTo(targetSize) == false {

            let widthFactor: CGFloat = targetWidth / width
            let heightFactor: CGFloat = targetHeight / height

            if widthFactor < heightFactor {
                scaleFactor = widthFactor
            }
            else {
                scaleFactor = heightFactor
            }

            scaledWidth  = width * scaleFactor
            scaledHeight = height * scaleFactor

            // center the image
            if widthFactor < heightFactor {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            } else if widthFactor > heightFactor {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
            }
        }

        // this is actually the interesting part:
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }
        var thumbnailRect:CGRect = .zero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight

        if radius > 0 {
            UIBezierPath(roundedRect: thumbnailRect, cornerRadius:2 * UIScreen.main.scale).addClip()
        }
        sourceImage.draw(in: thumbnailRect)
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    /// Returns a image that fills in newSize
    func resizedImage(_ newSize: CGSize) -> UIImage {
        // Guard newSize is different
        guard self.size != newSize else { return self }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    /// Returns a resized image that fits in rectSize, keeping it's aspect ratio
    /// Note that the new image size is not rectSize, but within it.
    func resizedImageWithinRect(_ rectSize: CGSize) -> UIImage {
        let widthFactor = size.width / rectSize.width
        let heightFactor = size.height / rectSize.height

        var resizeFactor = widthFactor
        if size.height > size.width {
            resizeFactor = heightFactor
        }

        let newSize = CGSize(width: size.width/resizeFactor, height: size.height/resizeFactor)
        let resized = resizedImage(newSize)
        return resized
    }

    static func image(for name: String, font: UIFont) -> UIImage? {
        var image: UIImage?
        if nil != UIImage(systemName: name) {
            let config = UIImage.SymbolConfiguration(font: font)
            image = UIImage(systemName: name,
                            withConfiguration: config)
            return image
        }
        image = UIImage(named: name)
        return image
    }

    func fixOrientation() -> UIImage {
        // No-op if the orientation is already correct
        if ( self.imageOrientation == UIImage.Orientation.up ) {
            return self;
        }

        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = CGAffineTransform.identity

        if ( self.imageOrientation == UIImage.Orientation.down || self.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        }

        if ( self.imageOrientation == UIImage.Orientation.left || self.imageOrientation == UIImage.Orientation.leftMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
        }

        if ( self.imageOrientation == UIImage.Orientation.right || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi / 2.0))
        }

        if ( self.imageOrientation == UIImage.Orientation.upMirrored || self.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }

        if ( self.imageOrientation == UIImage.Orientation.leftMirrored || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }

        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!;

        ctx.concatenate(transform)

        if ( self.imageOrientation == UIImage.Orientation.left ||
             self.imageOrientation == UIImage.Orientation.leftMirrored ||
             self.imageOrientation == UIImage.Orientation.right ||
             self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
        } else {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
        }

        // And now we just create a new UIImage from the drawing context and return it
        return UIImage(cgImage: ctx.makeImage()!)
    }

    func croppedImage(at rect: CGRect) -> UIImage {
        let sourceImageRef:CGImage = self.cgImage!
        let newImageRef:CGImage = sourceImageRef.cropping(to: rect)!
        let subImage = UIImage(cgImage: newImageRef)
        return subImage
    }
}
public extension UIImage {
    func isLandscapeCover() -> Bool {
        return self.size.width > self.size.height
    }
    func isPortraitCover() -> Bool {
        return self.size.height > self.size.width
    }
}
