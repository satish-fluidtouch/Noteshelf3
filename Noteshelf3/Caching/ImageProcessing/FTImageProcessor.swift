//
//  FTImageProcessor.swift
//  Noteshelf3
//
//  Created by Akshay on 23/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//
import Accelerate
import Foundation
import UIKit
import Vision

final class FTImageProcessor {
    static func process(url: URL) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            process(url: url) { image in
                continuation.resume(returning: image)
            }
        }
    }

    static func process(url: URL, completion: ((_ image: UIImage?) -> Void)?) {
        Task(priority: .utility) {
            guard let image = UIImage(contentsOfFile: url.path),
                  let cgImage = image.cgImage else {
                cacheLog(.error, "No source image")
                completion?(nil)
                return
            }
            cacheLog(.info, "Processing", url.path)
            let result = process(cgImage: cgImage,
                                 orientation: image.imageOrientation)
            completion?(result)
        }
    }

    static func process(cgImage: CGImage, orientation: UIImage.Orientation) -> UIImage {
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request: VNRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        try? requestHandler.perform([request])

        guard let saliencyObservation = request.results?.first as? VNSaliencyImageObservation,
              let salientObjects = saliencyObservation.salientObjects else {
            cacheLog(.error, "No source image")
            return UIImage(cgImage: cgImage, scale: 0.25, orientation: orientation)
        }

        // TODO: (AK) decide between Intersection and Union
        var salientRegions = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        for salientObject in salientObjects {
            salientRegions = salientRegions.intersection(salientObject.boundingBox)
        }

        let salientRect = VNImageRectForNormalizedRect(salientRegions, cgImage.width, cgImage.height)

        let croppedImage = cropCG(sourceImage: cgImage, salientRect: salientRect)
        return UIImage(cgImage: croppedImage, scale: 0.25, orientation: orientation)
    }

    private static func cropCG(sourceImage: CGImage, salientRect: CGRect) -> CGImage {
        if let croppedImage = sourceImage.cropping(to: salientRect) {
            cacheLog(.info, "Cropped to \(salientRect)")
            return croppedImage
        }
        return sourceImage
    }
}

// Less performant code for image cropping
private func crop(sourceImage: CGImage, salientRect: CGRect) -> UIImage? {
    do {
        var cgImageFormat: vImage_CGImageFormat = vImage_CGImageFormat()
        let src = try vImage.PixelBuffer<vImage.Interleaved8x4>(cgImage: sourceImage,
                                                                cgImageFormat: &cgImageFormat)
        // Perform image-processing operations on `buffer`.
        let croppedImage = src.cropped(to: salientRect)
        guard let destination = croppedImage.makeCGImage(cgImageFormat: cgImageFormat) else {
            return nil
        }
        return UIImage(cgImage: destination)
    } catch {
        cacheLog(.error, error)
        return nil
    }
}
