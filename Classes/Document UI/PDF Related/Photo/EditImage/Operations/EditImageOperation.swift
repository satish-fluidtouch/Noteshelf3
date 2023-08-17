//
//  EditImageOperation.swift
//  EditImage
//
//  Created by Matra on 11/05/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

enum FTImageEditOperation: Int {
    case none = 0
    case crop 
    case erase
    case lasso
}

class EditImageOperation {
    
    var editedImages = [UIImage]()
    var imageContext: CGContext!
    let radius : CGFloat = 20.0
    var imageToEdit : UIImage!
//    var numberOfAction = 0

    var canUndo : Bool  {
        get{
            return undoManager.canUndo
        }
    }
    var canRedo : Bool {
        get{
            return undoManager.canRedo
        }
    }
    var editMode : FTImageEditOperation = .none
    
    var undoManager = UndoManager()
    
    
    fileprivate func fromUItoQuartz(point: CGPoint, frameSize: CGSize) -> CGPoint{
        var newPoint = point
        newPoint.y = frameSize.height - point.y
        return newPoint
    }
    
    fileprivate func scalePoint(point: CGPoint, previousSize: CGSize, currentSize: CGSize) -> CGPoint {
        return  CGPoint(x: currentSize.width * point.x / previousSize.width, y: currentSize.height * point.y / previousSize.height)
    }
    
    func initializeWithImage(_ image: UIImage) {
        initializeContext(image: image)
        self.imageToEdit = image
//        addCroppedImage(image)
    }
    
    func addCroppedImage(_ image : UIImage) {
       weak var weakself = self
        undoManager.registerUndo(withTarget: self, handler: { [lastImage = self.imageToEdit] (_) -> Void in
            if lastImage != nil {
                weakself?.addCroppedImage(lastImage!)
            }
        })
        self.imageToEdit = image

    }
    
    func initializeToMode(mode: FTImageEditOperation, with image: UIImage ) {
        editMode = mode
        initializeContext(image: image)
//        if !undoManager.canUndo {
//            self.imageToEdit = image
////            addCroppedImage(image)
//        }
    }
    
    fileprivate func initializeContext(image: UIImage) {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let inputCGImage = image.cgImage
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bitmapInfo       = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        imageContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerPixel * width, space: colorSpace, bitmapInfo: bitmapInfo)
        imageContext.draw(inputCGImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        imageContext.setBlendMode(.clear)
        imageContext.setLineCap(.round)
        imageContext.setFillColor(UIColor.clear.cgColor)
        imageContext.setStrokeColor(UIColor.black.cgColor)
    }
    
    //MARK: - crop image
    func cropImageForSelectedPath(_ selectedPath: CGPath! , image: UIImage!, boundingBox: CGRect, lassoOffset: CGPoint) -> UIImage {
        let scale = image.size.width/boundingBox.width
        UIGraphicsBeginImageContext(image.size);
        let newContext = UIGraphicsGetCurrentContext();
        newContext?.clear(CGRect.init(origin: CGPoint.zero, size: image.size))
        let translation = CGAffineTransform.init(translationX: -(boundingBox.origin.x) + lassoOffset.x, y: -(boundingBox.origin.y) + lassoOffset.y)
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        transform = translation.concatenating(transform)
        let scaledPath = selectedPath.copy(using: &transform)
        let newBezierPath = UIBezierPath(cgPath: scaledPath!)
        newContext?.addPath(newBezierPath.cgPath)
        newContext?.clip()
        newContext?.translateBy(x: 0, y: image.size.height);
        newContext?.scaleBy(x: 1, y: -1);
        newContext?.draw(image.cgImage!, in: CGRect.init(origin: CGPoint.zero, size: image.size))
        let cgImage = newContext?.makeImage();
        let newImage = UIImage.init(cgImage: cgImage!)
        
        let newWidth = newImage.size.width < 100 ? 100.0 : newImage.size.width
        let newHeight = newImage.size.height < 100 ? 100.0 : newImage.size.height
         let newSize = CGSize(width: newWidth, height: newHeight)
        UIGraphicsBeginImageContext(newSize);
        let newContext1 = UIGraphicsGetCurrentContext();
        newContext1?.clip()
        newContext1?.clear(CGRect.init(origin: CGPoint.zero, size: newSize))
        newContext1?.translateBy(x: 0, y: newHeight);
        newContext1?.scaleBy(x: 1, y: -1);
        newContext1?.draw(newImage.cgImage!, in: CGRect.init(origin: CGPoint(x: (newWidth - newImage.size.width) / 2, y: (newHeight - newImage.size.height) / 2), size: newImage.size))
        let cgImage1 = newContext1?.makeImage();
        let newImage1 = UIImage.init(cgImage: cgImage1!)
        addCroppedImage(newImage1)
        return newImage1
    }
    

    
    //MARK:DRAW over image
    func touchPoints(touch: UITouch, onImage image: UIImage, endEditing: Bool, rect:CGRect) -> UIImage {
        let size = CGSize(width: image.size.width , height: image.size.height )
        let touchView = touch.view
//        let rect = AVMakeRect(aspectRatio: (image.size), insideRect: (touchView?.frame)!)
        let scale = size.width / rect.width
        var touchPoint = touch.location(in: touchView)
        
        if rect.contains(touchPoint) {
            touchPoint = fromUItoQuartz(point: touchPoint, frameSize: (touchView?.bounds.size)!)
            touchPoint = CGPoint(x: touchPoint.x - rect.origin.x, y: touchPoint.y - rect.origin.y)
            touchPoint = CGPoint(x: touchPoint.x * scale, y: touchPoint.y * scale)
            
            var prePoint = touch.previousLocation(in: touchView)
            prePoint = fromUItoQuartz(point: prePoint, frameSize: (touchView?.bounds.size)!)
            prePoint = CGPoint(x: prePoint.x - rect.origin.x, y: prePoint.y - rect.origin.y)
            prePoint = CGPoint(x: prePoint.x * scale, y: prePoint.y * scale)
            
            imageContext.setLineWidth(CGFloat(radius * scale))
            
            let linePath = UIBezierPath()
            linePath.move(to: prePoint)
            linePath.addLine(to: touchPoint)
            
            imageContext.addPath(linePath.cgPath)
            imageContext.strokePath()

            let cgImage = imageContext.makeImage()
            let newImage = UIImage.init(cgImage: cgImage!)
            if endEditing == true {
                addCroppedImage(newImage)
            }
            return newImage
        }

        
        return image
    }
    // undo
    func undo() -> UIImage{
        undoManager.undo()
        if editMode == .erase {
            initializeContext(image: self.imageToEdit)
        }
        return self.imageToEdit

    }
    
    func redo() -> UIImage {
        undoManager.redo()
        if editMode == .erase {
            initializeContext(image: self.imageToEdit)
        }
        return self.imageToEdit

    }
    
    func resetEditedImages(initialImage: UIImage?) {
        undoManager.removeAllActions()
        imageToEdit = initialImage
        if initialImage != nil {
            initializeContext(image: initialImage!)
        }
    }
}
