//
//  ImageAnimationHelper.swift
//  EditImage
//
//  Created by Matra on 07/06/18.
//  Copyright © 2018 Matra. All rights reserved.
//

import Foundation
import UIKit

class ImageAnimationHelper {

    var imageContext: CGContext!
    let radius: CGFloat = 20.0
    var pointsArray = [[[String: CGFloat]]]()

    func initializeContext(image: UIImage) {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let inputCGImage = image.cgImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        imageContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerPixel * width, space: colorSpace, bitmapInfo: bitmapInfo)
        imageContext.draw(inputCGImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        imageContext.setBlendMode(.clear)
        imageContext.setLineCap(.round)
        imageContext.setFillColor(UIColor.clear.cgColor)
        imageContext.setStrokeColor(UIColor.black.cgColor)
    }

    // MARK: DRAW over image
    func drawPoints(prePoint: CGPoint, currentPoint: CGPoint, newImage: UIImage, imageRect: CGRect) -> UIImage {
//        imageContext.clear(CGRect(x: 0, y: 0, width: Int(newImage.size.width), height: Int(newImage.size.height)))
//        imageContext.draw(newImage.cgImage!, in: CGRect(x: 0, y: 0, width: Int(newImage.size.width), height: Int(newImage.size.height)))
        initializeContext(image: newImage)
        let scale = newImage.size.width / imageRect.width
        let linePath = UIBezierPath()
        linePath.move(to: prePoint)
        linePath.addLine(to: currentPoint)
        imageContext.setLineWidth(radius * scale)
        imageContext.addPath(linePath.cgPath)
        imageContext.strokePath()
        let cgImage = imageContext.makeImage()
        let image = UIImage(cgImage: cgImage!)

        return image
    }

}
