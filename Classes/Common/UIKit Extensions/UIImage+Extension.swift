//
//  UIImage+Extension.swift
//  Noteshelf
//
//  Created by Sameer on 16/10/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
extension UIImage {
    @objc func coverStyle() -> FTCoverStyle
    {
        var position = FTCoverStyle.default
        if(self.size.width.remainder(dividingBy: FTCoverStyle.transparent.coverSize().width) == 0) {
            position = FTCoverStyle.transparent
        }
        else if(self.size.width.remainder(dividingBy: FTCoverStyle.audio.coverSize().width) == 0) {
            position = FTCoverStyle.audio
        }
        else if(self.size.width.remainder(dividingBy: FTCoverStyle.clearWhite.coverSize().width) == 0) {
            position = FTCoverStyle.clearWhite
        }
        return position
     }
     
     @objc func coverSize() -> CGSize
     {
         let style = self.coverStyle();
         return style.coverSize();
     }

     @objc func coverLabelStyle() -> FTCoverLabelStyle
     {
         let position = self.coverStyle();
         var labelPosition : FTCoverLabelStyle;
         switch position {
         case .transparent, .audio, .clearWhite:
             labelPosition = .bottom;
         default:
             labelPosition = .default;
         }
         return labelPosition;
     }
    
    convenience init(view: UIView) {
          UIGraphicsBeginImageContext(view.frame.size)
          view.layer.render(in:UIGraphicsGetCurrentContext()!)
          let image = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          self.init(cgImage: image!.cgImage!)
    }
   
   func tint(with color: UIColor) -> UIImage
   {
       UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
       defer { UIGraphicsEndImageContext() }
       guard let context = UIGraphicsGetCurrentContext() else { return self }
       
       // flip the image
       context.scaleBy(x: 1.0, y: -1.0)
       context.translateBy(x: 0.0, y: -self.size.height)
       
       // multiply blend mode
       context.setBlendMode(.multiply)
       
       let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
       context.clip(to: rect, mask: self.cgImage!)
       color.setFill()
       context.fill(rect)
       
       // create UIImage
       guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }
       
       return newImage
   }
    
    func applying(contrast value: NSNumber) -> UIImage? {
       guard
           let ciImage = CIImage(image: self)?.applyingFilter("CIColorControls",
                                                              parameters: [kCIInputContrastKey: value])
           else { return nil }
       UIGraphicsBeginImageContextWithOptions(size, false, scale)
       defer { UIGraphicsEndImageContext() }
       UIImage(ciImage: ciImage).draw(in: CGRect(origin: .zero, size: size))
       return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func resizedImageWithSize(_ targetSize:CGSize) -> UIImage {

        let sourceImage = self
        var newImage : UIImage?

        let imageSize:CGSize = sourceImage.size
        let width:CGFloat = imageSize.width
        let height:CGFloat = imageSize.height

        let targetWidth:CGFloat = targetSize.width
        let targetHeight:CGFloat = targetSize.height

        var scaleFactor:CGFloat = 0.0
        var scaledWidth:CGFloat = targetWidth
        var scaledHeight:CGFloat = targetHeight

        if imageSize.equalTo(targetSize) == false {

            let widthFactor:CGFloat = targetWidth / width
            let heightFactor:CGFloat = targetHeight / height

            if widthFactor < heightFactor
                {scaleFactor = widthFactor}
            else
                {scaleFactor = heightFactor}

            scaledWidth  = width * scaleFactor
            scaledHeight = height * scaleFactor

        }

        var thumbnailRect:CGRect = .zero
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight

        UIGraphicsBeginImageContextWithOptions(thumbnailRect.size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }

        sourceImage.draw(in: thumbnailRect)

        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if newImage == nil {
            debugLog("could not scale image")
        }
        return newImage ?? self
    }

    func resizeTo1xImage() -> UIImage {
        var rect:CGRect = .zero
        if self.scale == 1.0 {
            rect = CGRect(x: 0, y: 0, width: self.size.width/2, height: self.size.height/2)
        } else {
            rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        }
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }

    func resizedImageWithSizeIfBigger(_ targetSize:CGSize) -> UIImage {

        //do not resize if the actual size is within the bounds
        if self.size.width <= targetSize.width && self.size.height <= targetSize.height {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
          context.interpolationQuality = CGInterpolationQuality.high
        }
        let horizontalRatio:CGFloat = targetSize.width / self.size.width
        let verticalRatio:CGFloat = targetSize.height / self.size.height
        var ratio:CGFloat
        ratio = min(horizontalRatio, verticalRatio)
        let newSize:CGSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)

        let xPos:CGFloat = (targetSize.width - newSize.width)/2
        let yPos:CGFloat = (targetSize.height - newSize.height)/2

        self.draw(in: CGRect(x: xPos, y: yPos, width: newSize.width, height: newSize.height))

        // An autoreleased image
        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return newImage ?? self
    }

    func imageAtRect(rect:CGRect) -> UIImage {

        /*
        CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
        UIImage* subImage = [UIImage imageWithCGImage: imageRef];
        CGImageRelease(imageRef);
        */
        var rect = rect
        rect.size.height += rect.size.height * self.scale
        rect.size.width += rect.size.width * self.scale
        rect.origin.x += rect.origin.x * self.scale
        rect.origin.y += rect.origin.y * self.scale
        let sourceImageRef:CGImage = self.cgImage!
        let newImageRef:CGImage = sourceImageRef.cropping(to: rect)!
        let subImage = UIImage(cgImage: newImageRef, scale:self.scale, orientation:self.imageOrientation)
        return subImage

    }
    
    func scaleDownIf2x() -> UIImage {

        if self.scale == 1.0 {
            return self
        }

        let scaledImageSize:CGSize = CGSize(width: self.size.width, height: self.size.height)

        UIGraphicsBeginImageContextWithOptions(scaledImageSize, false, 1.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }
        //CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor redColor].CGColor);
        //CGContextFillRect(UIGraphicsGetCurrentContext(), CGRect(0, 0, scaledImageSize.width, scaledImageSize.height));

        self.draw(in: CGRect(x: 0, y: 0, width: scaledImageSize.width, height: scaledImageSize.height))

        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageCopy ?? self
    }

    func scaleUpTo2x() -> UIImage {

        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))

        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageCopy ?? self
    }

    func imageByScalingProportionallyToMinimumSize(_ targetSize:CGSize) -> UIImage {

        let sourceImage = self
        var newImage:UIImage?

        let imageSize:CGSize = sourceImage.size
        let width:CGFloat = imageSize.width
        let height:CGFloat = imageSize.height

        let targetWidth:CGFloat = targetSize.width
        let targetHeight:CGFloat = targetSize.height

        var scaleFactor:CGFloat = 0.0
        var scaledWidth:CGFloat = targetWidth
        var scaledHeight:CGFloat = targetHeight

        var thumbnailPoint:CGPoint = CGPoint(x: 0.0,y: 0.0)

        if imageSize.equalTo(targetSize) == false {

            let widthFactor:CGFloat = targetWidth / width
            let heightFactor:CGFloat = targetHeight / height

            if widthFactor > heightFactor
                {scaleFactor = widthFactor}
            else
                {scaleFactor = heightFactor}

            scaledWidth  = width * scaleFactor
            scaledHeight = height * scaleFactor

            // center the image

            if widthFactor > heightFactor {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            } else if widthFactor < heightFactor {
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

        sourceImage.draw(in: thumbnailRect)

        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if newImage == nil {debugLog("could not scale image")}


        return newImage ?? self
    }

    func imageByScalingToSize(targetSize:CGSize) -> UIImage {

        let sourceImage = self
        var newImage : UIImage?

        //   CGSize imageSize = sourceImage.size;
        //   CGFloat width = imageSize.width;
        //   CGFloat height = imageSize.height;

        let targetWidth:CGFloat = targetSize.width
        let targetHeight:CGFloat = targetSize.height

        //   CGFloat scaleFactor = 0.0;
        let scaledWidth:CGFloat = targetWidth
        let scaledHeight:CGFloat = targetHeight

        let thumbnailPoint:CGPoint = CGPoint(x: 0.0,y: 0.0)

        // this is actually the interesting part:

        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }
        var thumbnailRect:CGRect = .zero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width  = scaledWidth
        thumbnailRect.size.height = scaledHeight

        sourceImage.draw(in: thumbnailRect)

        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if newImage == nil {debugLog("could not scale image")}


        return newImage ?? self
    }


    private func imageRotatedByDegrees(_ degrees:CGFloat) -> UIImage {
        // calculate the size of the rotated view's containing box for our drawing space
        var rotatedViewBox = CGRect(x: 0,y: 0,width: self.size.width, height: self.size.height);
        let t:CGAffineTransform = CGAffineTransform(rotationAngle: degrees.degreesToRadians)
        rotatedViewBox = rotatedViewBox.applying(t).integral;
        let rotatedSize:CGSize = rotatedViewBox.size

        // Create the bitmap context
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }
        let bitmap:CGContext = UIGraphicsGetCurrentContext()!

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width/2, y: rotatedSize.height/2)

        //   // Rotate the image context
        bitmap.rotate(by: degrees.degreesToRadians)

        // Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        if let cgImage = self.cgImage {
            bitmap.draw(cgImage, in:  CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self

    }

    func imageRotatedByRadians(_ radians:CGFloat) -> UIImage {
        return self.imageRotatedByDegrees(radians.radiansToDegrees)
    }

    // Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
    // The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
    // If the new size is not integral, it will be rounded up
    func resizedImage(newSize:CGSize, transform:CGAffineTransform, drawTransposed transpose:Bool, interpolationQuality quality:CGInterpolationQuality) -> UIImage {
        let newRect:CGRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        let transposedRect:CGRect = CGRect(x: 0, y: 0, width: newRect.size.height, height: newRect.size.width)
        let imageRef:CGImage = self.cgImage!

        // Build a context that's the same dimensions as the new size
        let bitmap:CGContext = CGContext(data: nil,
                                         width: Int(newRect.size.width),
                                         height: Int(newRect.size.height),
                                         bitsPerComponent: imageRef.bitsPerComponent,
                                         bytesPerRow: 0,
                                         space: imageRef.colorSpace!,
                                         bitmapInfo: imageRef.bitmapInfo.rawValue)!

        // Rotate and/or flip the image if required by its orientation
        bitmap.concatenate(transform)

        // Set the quality level to use when rescaling
        bitmap.interpolationQuality = quality

        // Draw into the context; this scales the image
        bitmap.draw(imageRef, in: transpose ? transposedRect : newRect)

        // Get the resized image from the context and a UIImage
        let newImageRef:CGImage = bitmap.makeImage()!
        let newImage = UIImage(cgImage: newImageRef)

        return newImage
    }

    func resizedImage(newSize:CGSize, transform:CGAffineTransform, clippingRect clipRect:CGRect, includeBorder:Bool) -> UIImage {
        return self.resizedImage(newSize: newSize, transform:transform,
                     clippingRect:clipRect,
                     screenScale:UIScreen.main.scale,
                    includeBorder:includeBorder)
    }

    func resizedImage(newSize:CGSize, transform:CGAffineTransform, clippingRect clipRect:CGRect, screenScale:CGFloat, includeBorder:Bool) -> UIImage {
        //NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];

        let rect = CGRect(x: 0, y: 0, width: clipRect.size.width, height: clipRect.size.height).integral

        let scaledImageSize = CGSize(width: self.size.width/screenScale, height: self.size.height/screenScale)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, screenScale)

        // End the drawing
        defer {
            UIGraphicsEndImageContext()
        }

        guard let ctx:CGContext = UIGraphicsGetCurrentContext() else {
            return self
        }
        ctx.interpolationQuality = .low

        // Transform the image (as the image view has been transformed)
        ctx.translateBy(x: newSize.width*0.5 - clipRect.origin.x, y: newSize.height*0.5 - clipRect.origin.y)
        ctx.concatenate(transform)
        ctx.translateBy(x: -scaledImageSize.width*0.5, y: -scaledImageSize.height*0.5)

        ctx.translateBy(x: 0.0, y: scaledImageSize.height)
        ctx.scaleBy(x: 1.0, y: -1.0)

        // Draw view into context
        if let cgImage = self.cgImage {
            ctx.draw(cgImage, in: CGRect(x: 0,y: 0,width: scaledImageSize.width, height: scaledImageSize.height))
        }

        if includeBorder {

            //Implement someday:

            //CGContextAddRect(ctx, CGRectInset(CGRect(0,0,self.size.width, self.size.height),2,2));
            //CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
            //CGContextSetLineWidth(ctx, 10);
            //CGContextStrokePath(ctx);
        }

        // Create the new UIImage from the context
        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        //NSTimeInterval t2 = [NSDate timeIntervalSinceReferenceDate];

        //print(@"%.0f", (t2-t1)*1000);

        return newImage ?? self
    }

    func scaleAndRotateImage() -> UIImage {
        let kMaxResolution:Int = 864 * 2 // Or whatever

        let imgRef:CGImage = self.cgImage!

        let width:CGFloat = CGFloat(imgRef.width)
        let height:CGFloat = CGFloat(imgRef.height)

        var transform:CGAffineTransform = .identity
        var bounds:CGRect = CGRect(x: 0, y: 0, width: width, height: height)

        if width > CGFloat(kMaxResolution) || height > CGFloat(kMaxResolution) {
           let ratio = width / height
           if ratio > 1 {
               bounds.size.width = CGFloat(kMaxResolution)
               bounds.size.height = bounds.size.width / ratio
           } else {
               bounds.size.height = CGFloat(kMaxResolution)
               bounds.size.width = bounds.size.height * ratio
           }
        }

        let scaleRatio:CGFloat = bounds.size.width / width
        let imageSize:CGSize = CGSize(width: CGFloat(imgRef.width), height: CGFloat(imgRef.height))
        var boundHeight:CGFloat
        let orient:UIImage.Orientation = self.imageOrientation
        switch(orient) {

        case .up: //EXIF = 1
            transform = .identity
        case .upMirrored: //EXIF = 2
                transform = CGAffineTransform(translationX: imageSize.width, y: 0.0)
                transform = transform.scaledBy(x: -1.0, y: 1.0)
        case .down: //EXIF = 3
                transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height)
                transform = transform.rotated(by: CGFloat.pi)
        case .downMirrored: //EXIF = 4
                transform = CGAffineTransform(translationX: 0.0, y: imageSize.height)
                transform = transform.scaledBy(x: 1.0, y: -1.0)
        case .leftMirrored: //EXIF = 5
                boundHeight = bounds.size.height
                bounds.size.height = bounds.size.width
                bounds.size.width = boundHeight
                transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
                transform = transform.scaledBy(x: -1.0, y: 1.0)
                transform = transform.rotated(by: CGFloat(3.0 * CGFloat.pi / 2.0))
        case .left: //EXIF = 6
                boundHeight = bounds.size.height
                bounds.size.height = bounds.size.width
                bounds.size.width = boundHeight
                transform = CGAffineTransform(translationX: 0.0, y: imageSize.width)
                transform = transform.rotated(by: CGFloat(3.0 * CGFloat.pi / 2.0))
        case .rightMirrored: //EXIF = 7
                boundHeight = bounds.size.height
                bounds.size.height = bounds.size.width
                bounds.size.width = boundHeight
                transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                transform = transform.rotated(by: CGFloat(CGFloat.pi / 2.0))
        case .right: //EXIF = 8
                boundHeight = bounds.size.height
                bounds.size.height = bounds.size.width
                bounds.size.width = boundHeight
                transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
                transform = transform.rotated(by: CGFloat(CGFloat.pi / 2.0))
        default:
                 NSException(name:NSExceptionName.internalInconsistencyException, reason:"Invalid image orientation", userInfo:nil).raise()
        }

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
        }

        let context:CGContext = UIGraphicsGetCurrentContext()!

        if orient == .right || orient == .left {
            context.scaleBy(x: -scaleRatio, y: scaleRatio)
            context.translateBy(x: -height, y: 0)
        }
        else if orient == .rightMirrored || orient == .leftMirrored {
            context.scaleBy(x: scaleRatio, y: -scaleRatio)

            context.translateBy(x: 0, y: -width)

        }
        else {
            context.scaleBy(x: scaleRatio, y: -scaleRatio)
            context.translateBy(x: 0, y: -height)
        }

        /*

         //Replaced with above to fix a bug in the code

         if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
         CGContextScaleCTM(context, -scaleRatio, scaleRatio);
         CGContextTranslateCTM(context, -height, 0);
         }
         else {
         CGContextScaleCTM(context, scaleRatio, -scaleRatio);
         CGContextTranslateCTM(context, 0, -height);
         }
         */

        context.concatenate(transform)
        context.draw(imgRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageCopy ?? self
    }

    func overlayImage(anotherImage:UIImage?) -> UIImage {
        //Assumes that both images are of the same size
        guard let anotherImage = anotherImage else{
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)

        if let context = UIGraphicsGetCurrentContext() {
                   context.interpolationQuality = .high
               }
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))

        anotherImage.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))

        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageCopy ?? self
    }

    func grabImageFromView(viewToGrab:UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(viewToGrab.bounds.size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
                   context.interpolationQuality = .high
               }
        viewToGrab.layer.render(in: UIGraphicsGetCurrentContext()!)
        let viewImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return viewImage ?? self
    }

    func stretchImage(to size: CGSize, edgeInsets: UIEdgeInsets) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
        }
        if responds(to: #selector(self.resizableImage(withCapInsets:))) {
            resizableImage(withCapInsets: edgeInsets).draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        } else {
            stretchableImage(withLeftCapWidth: Int(edgeInsets.left), topCapHeight: Int(edgeInsets.top)).draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }

        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageCopy
    }

    func image(byAddingExposure exposureValue: CGFloat) -> UIImage? {
        let inputImage = CIImage(image: self)
        let exposureAdjustmentFilter = CIFilter(name: "CIExposureAdjust")
        exposureAdjustmentFilter?.setDefaults()
        exposureAdjustmentFilter?.setValue(inputImage, forKey: "inputImage")
        exposureAdjustmentFilter?.setValue(NSNumber(value: Float(exposureValue)), forKey: "inputEV")
        let outputImage = exposureAdjustmentFilter?.value(forKey: "outputImage") as? CIImage
        let context = CIContext(options: nil)
        if let outputImage = outputImage, let create = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: create)
        }
        return nil
    }
    
    
   func imageByRemovingShadows() -> UIImage? {
        var outputImage = CIImage(image: self)
        let filter = CIFilter(name: "CIHighlightShadowAdjust")
        filter?.setDefaults()
        filter?.setValue(outputImage, forKey: kCIInputImageKey)
        filter?.setValue(NSNumber(value: 1), forKey: "inputHighlightAmount")
        filter?.setValue(NSNumber(value: 10), forKey: "inputShadowAmount")
        outputImage = filter?.outputImage

        let exposureAdjustmentFilter = CIFilter(name: "CIExposureAdjust")
        exposureAdjustmentFilter?.setDefaults()
        exposureAdjustmentFilter?.setValue(outputImage, forKey: "inputImage")
        exposureAdjustmentFilter?.setValue(NSNumber(value: 0.3), forKey: "inputEV")
        outputImage = exposureAdjustmentFilter?.value(forKey: "outputImage") as? CIImage

        let adjustments = outputImage?.autoAdjustmentFilters(options: nil)

        for filter in adjustments! {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            outputImage = filter.outputImage
        }
        let context = CIContext(options: nil)
        return UIImage(cgImage: context.createCGImage(outputImage!, from:outputImage!.extent)!)
    }
    
   @objc func resizeImage(to newSize: CGSize, transform: CGAffineTransform, clippingRect clipRect: CGRect) -> UIImage? {
        let rect1 = CGRect(x: 0, y: 0, width: clipRect.size.width, height: clipRect.size.height)
        let rect = rect1.integral
        
        let scaledImageSize = CGSize(width: size.width, height: size.height)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(rect.size, _: false, _: 0.0)
        //        CGContextSetInterpolationQuality(context, CGInterpolationQuality.low)
        
        // Transform the image (as the image view has been transformed)
        context.translateBy(x: newSize.width * 0.5 - clipRect.origin.x, y: newSize.height * 0.5 - clipRect.origin.y)
        context.concatenate(transform)
        context.translateBy(x: -scaledImageSize.width * 0.5, y: -scaledImageSize.height * 0.5)
        
        context.translateBy(x: 0.0, y: scaledImageSize.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Draw view into context
        context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: scaledImageSize.width, height: scaledImageSize.height))
        // Create the new UIImage from the context
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the drawing
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
   @objc func scaleDownToHalf() -> UIImage? {
        let scaledImageSize = CGSize(width: size.width * 0.5, height: size.height * 0.5)
        
        UIGraphicsBeginImageContextWithOptions(scaledImageSize, _: false, _: 1.0)
        //        CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), CGInterpolationQuality.high)
        
        draw(in: CGRect(x: 0, y: 0, width: scaledImageSize.width, height: scaledImageSize.height))
        
        let imageCopy: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return imageCopy
    }
}

//MARK:- UNUSED -
private extension UIImage {
    func imageRotatedByDegrees1x(_ degrees:CGFloat) -> UIImage {
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame:CGRect(x: 0,y: 0,width: self.size.width, height: self.size.height))
        let t:CGAffineTransform = CGAffineTransform(rotationAngle: degrees.degreesToRadians)
        rotatedViewBox.transform = t
        let rotatedSize:CGSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 1.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = CGInterpolationQuality.high
        }
        let bitmap:CGContext = UIGraphicsGetCurrentContext()!
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width/2, y: rotatedSize.height/2)
        
        //   // Rotate the image context
        bitmap.rotate(by: degrees.degreesToRadians)
        
        // Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        if let cgImage = self.cgImage {
            bitmap.draw(cgImage, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
        
    }
    
    func imageRotatedByRadians1x(_ radians:CGFloat) -> UIImage {
        return self.imageRotatedByDegrees1x(radians.radiansToDegrees)
    }
    
    func saveImageToDocumentsFolderWithRandomSuffix(filenameExcludingExt:String) {
        #if DEBUG
        let fileName = String(format:"%@%d.png", filenameExcludingExt, arc4random() % 10000)
        self.saveImageToDocumentsFolder(filename: fileName)
        #endif
    }
    
    func saveImageToDocumentsFolder(filename:String) {
        #if DEBUG
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [AnyObject]
        let documentsDirectory = paths[0] as? String ?? ""
        let fullPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(filename).path

        if let data = self.pngData() as NSData? {
            data.write(toFile: fullPath, atomically:true)
        }
        #endif
    }
}
