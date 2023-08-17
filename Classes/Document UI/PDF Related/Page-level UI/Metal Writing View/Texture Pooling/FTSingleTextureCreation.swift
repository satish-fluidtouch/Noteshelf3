//
//  FTSingleTextureCreation.swift
//  Noteshelf
//
//  Created by Akshay on 20/01/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

final class FTSingleTextureCreation {

    static func createBackgroundTexture(for page: FTPageProtocol, targetRect: CGRect) -> MTLTexture? {
        guard let pageRef = page.pdfPageRef?.copy() as? PDFPage else { return nil }

        var pdfBox = PDFDisplayBox.mediaBox;
        var cgpdfBox = CGPDFBox.mediaBox;
        let documentVersion = page.templateInfo.version.floatValue;
        if(documentVersion > Float(0)) {
            pdfBox = PDFDisplayBox.cropBox;
            cgpdfBox = CGPDFBox.cropBox;
        }

        var pageRect = pageRef.bounds(for: pdfBox)
        if (pageRect.size.width == 0 || pageRect.size.height == 0 ) {
            return nil;
        }
        var rotatedAngle = 360 - CGFloat(page.rotationAngle);
        if(rotatedAngle >= 360) {
            rotatedAngle = 360 - rotatedAngle
        }

        if(documentVersion > Float(0)) {
            let trasnform = pageRef.transform(for: pdfBox);
            pageRect = pageRect.applying(trasnform)
            let rotate = CGAffineTransform(rotationAngle: rotatedAngle.degreesToRadians);
            pageRect = pageRect.applying(rotate);
            pageRect.origin = CGPoint.zero;
        }
        else {
            pageRect = pageRef.pageRef!.getBoxRect(cgpdfBox);
            let transform = pageRef.pageRef?.getDrawingTransform(CGPDFBox.mediaBox, rect: pageRect, rotate: Int32(rotatedAngle), preserveAspectRatio: true);
            pageRect = pageRect.applying(transform!);
            pageRect.origin = CGPoint.zero;
        }

        let aspectSize = textureSizeWRTScreen(pageRect.size);
        pageRect.size = aspectSize;

        let scale = page.templateInfo.isImageTemplate ? 2 : textureScaleWRTScreen(targetRect.size);

        let totalScaleFactor = scale*UIScreen.main.scale;

        pageRect = CGRectScale(pageRect, totalScaleFactor);
        let pageSizeForGL = CGSize.aspectFittedSize(pageRect.size, max: CGSize.init(width: maxTextureSize, height: maxTextureSize));
        let textureScale =  pageSizeForGL.height / pageRect.size.height;
        pageRect.size = pageSizeForGL;

        let cref = CGColorSpaceCreateDeviceRGB();

        let width = Int(pageRect.width).cappedToMaxTextureSize;
        let height = Int(pageRect.height).cappedToMaxTextureSize;
        guard let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.stride) else {
            return nil;
        }
        defer {
            free(rawData);
        }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        let options = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let context = CGContext.init(data: rawData,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: bitsPerComponent,
                                           bytesPerRow: bytesPerRow,
                                           space: cref,
                                           bitmapInfo: options) else {
            return nil
        }
        context.setFillColor(UIColor.white.cgColor);
        context.fill(pageRect);

        context.translateBy(x: 0, y: pageRect.height);
        context.scaleBy(x: 1, y: -1);

        let midx = CGFloat(width)*0.5;
        let midy = CGFloat(height)*0.5;

        context.translateBy(x: midx, y: midy);
        context.rotate(by: rotatedAngle.degreesToRadians);
        if(rotatedAngle == 0 || rotatedAngle == 180) {
            context.translateBy(x: -midx, y: -midy);
        }
        else {
            context.translateBy(x: -midy, y: -midx);
        }

        let templateInfo = page.templateInfo;
        context.concatenate(drawingTransform(pageRef,
                                             pageRect,
                                             totalScaleFactor*textureScale,
                                             pdfBox,
                                             Int32(rotatedAngle),
                                             templateInfo.version));
        context.interpolationQuality = CGInterpolationQuality.none;
        if(documentVersion > 0) {
            pageRef.displaysAnnotations = templateInfo.renderAnnotations;
            pageRef.draw(with: pdfBox, to: context);
        }
        else {
            context.drawPDFPage(pageRef.pageRef!);
        }


        if let pageWithColor = page as? FTPageBackgroundColorProtocol, page.templateInfo.isTemplate {
            let color = context.colorAt(x: 1, y: 1)
            pageWithColor.updateBackgroundColor(color: color)
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = .shaderRead;
        guard let texture = mtlDevice.makeTexture(descriptor: textureDescriptor) else {
            #if DEBUG
                fatalError("Unable to create Background Texture, DEBUG for the reason.")
            #else
                return nil
            #endif
        }
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region,
                        mipmapLevel: 0,
                        withBytes: rawData,
                        bytesPerRow: bytesPerRow)
        return texture;
    }
}

extension CGContext {
    func colorAt(x: Int, y: Int) -> UIColor {
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
