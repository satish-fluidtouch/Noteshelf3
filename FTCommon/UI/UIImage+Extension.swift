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
    
    @objc func scaleAndRotateImageFor1x() -> UIImage? {
         let maxRect: CGRect = UIScreen.main.bounds
         let kMaxResolution = max(1500, max(maxRect.size.width, maxRect.size.height)) // Or whatever
         
         guard let imgRef = cgImage else {
             return self
         }
         
         let width =  imgRef.width
         let height = imgRef.height
         
         var transform: CGAffineTransform = .identity
         var bounds = CGRect(x: 0, y: 0, width: width, height: height)
         
         if width > Int(kMaxResolution) || height > Int(kMaxResolution) {
             let ratio: CGFloat = CGFloat(width) / CGFloat(height)
             if ratio > 1 {
                 bounds.size.width = kMaxResolution
                 bounds.size.height = bounds.size.width / ratio
             } else {
                 bounds.size.height = kMaxResolution
                 bounds.size.width = bounds.size.height * ratio
             }
         }
         
         let scaleRatio: CGFloat = bounds.size.width / CGFloat(width)
         let imageSize = CGSize(width: imgRef.width, height: imgRef.height)
         let boundHeight: CGFloat
         let orient: UIImage.Orientation = imageOrientation
         switch orient {
         case UIImage.Orientation.up /*EXIF = 1 */:
             transform = CGAffineTransform.identity
         case UIImage.Orientation.upMirrored /*EXIF = 2 */:
             transform = CGAffineTransform(translationX: imageSize.width, y: 0.0)
             transform = transform.scaledBy(x: -1.0, y: 1.0)
         case UIImage.Orientation.down /*EXIF = 3 */:
             transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height)
             transform = transform.rotated(by: .pi)
         case UIImage.Orientation.downMirrored /*EXIF = 4 */:
             transform = CGAffineTransform(translationX: 0.0, y: imageSize.height)
             transform = transform.scaledBy(x: 1.0, y: -1.0)
         case UIImage.Orientation.leftMirrored /*EXIF = 5 */:
             boundHeight = bounds.size.height
             bounds.size.height = bounds.size.width
             bounds.size.width = boundHeight
             transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
             transform = transform.scaledBy(x: -1.0, y: 1.0)
             transform = transform.rotated(by: 3.0 * .pi / 2.0)
         case UIImage.Orientation.left /*EXIF = 6 */:
             boundHeight = bounds.size.height
             bounds.size.height = bounds.size.width
             bounds.size.width = boundHeight
             transform = CGAffineTransform(translationX: 0.0, y: imageSize.width)
             transform = transform.rotated(by: 3.0 * .pi / 2.0)
         case UIImage.Orientation.rightMirrored /*EXIF = 7 */:
             boundHeight = bounds.size.height
             bounds.size.height = bounds.size.width
             bounds.size.width = boundHeight
             transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
             transform = transform.rotated(by: .pi / 2.0)
         case UIImage.Orientation.right /*EXIF = 8 */:
             boundHeight = bounds.size.height
             bounds.size.height = bounds.size.width
             bounds.size.width = boundHeight
             transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
             transform = transform.rotated(by: .pi / 2.0)
         default:
             NSException(name:NSExceptionName.internalInconsistencyException, reason:"Invalid image orientation", userInfo:nil).raise()
         }
         
         UIGraphicsBeginImageContextWithOptions(bounds.size, _: false, _: 1.0)
         let context = UIGraphicsGetCurrentContext()
         context?.interpolationQuality = CGInterpolationQuality.high;
         
         if orient == .right || orient == .left {
             context?.scaleBy(x: -scaleRatio, y: scaleRatio)
             context?.translateBy(x: CGFloat(-height), y: 0)
         } else if orient == .rightMirrored || orient == .leftMirrored {
             context?.scaleBy(x: scaleRatio, y: -scaleRatio)
             
             context?.translateBy(x: 0, y: CGFloat(-width))
         } else {
             context?.scaleBy(x: scaleRatio, y: -scaleRatio)
             context?.translateBy(x: 0, y: CGFloat(-height))
         }
         context?.concatenate(transform)
         
         context?.draw(imgRef, in: CGRect(x: 0, y: 0, width: width, height: height))
         let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         
         return imageCopy
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
