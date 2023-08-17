//
//  FTTiledTextureCreation.swift
//  Metallic
//
//  Created by Akshay on 21/12/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import PDFKit
import FTRenderKit

private let bytesPerPixel = 4

class FTNoteshelfBGTextureTileContent: FTBackgroundTextureTileContent {
    weak var page: FTPageProtocol?

    convenience init(page: FTPageProtocol, contentSize: CGSize) {

        let tileSize: CGSize
        let tileCacheLimit: Int

        if(contentSize.width / 1024 > 3 || contentSize.height / 1024 > 3) {
            tileSize = CGSize(width: 1024, height: 1024)
            tileCacheLimit = 8
        } else {
            tileSize = CGSize(width: 512, height: 512)
            tileCacheLimit = 30
        }

        self.init(contentSize: contentSize,
                  tileSize: tileSize,
                  tileCacheLimit: tileCacheLimit)
        self.page = page
    }

    override func updateTextures(for tiles: [FTTextureTile], targetSize: CGSize, request: FTRenderRequest) {
        if let _page = self.page, !tiles.isEmpty {
            let roundedScale = textureScaleWRTScreen(targetSize)
            let totalScalefactor : CGFloat = roundedScale*UIScreen.main.scale
            objc_sync_enter(self)
            generateAndFillEmptyTiles(tiles: tiles,
                                      scaledPageSize: self.contentSize,
                                      noteshelfPage: _page,
                                      totalScalefactor: totalScalefactor,
                                      request: request)
            objc_sync_exit(self)
        }
    }
}

private extension FTBackgroundTextureTileContent {
    func generateAndFillEmptyTiles(tiles: [FTTextureTile],
                                   scaledPageSize: CGSize,
                                   noteshelfPage: FTPageProtocol,
                                   totalScalefactor: CGFloat,
                                   request: FTRenderRequest) {

        guard let page = noteshelfPage.pdfPageRef,
              scaledPageSize.width != 0,
              scaledPageSize.height != 0,
              !request.isCancelled else {
            return
        }

        let pdfBox : PDFDisplayBox
        let documentVersion = noteshelfPage.templateInfo.version.floatValue;
        if(documentVersion > Float(0)) {
            pdfBox = PDFDisplayBox.cropBox;
        } else {
            pdfBox = PDFDisplayBox.mediaBox;
        }

        let width = Int(tileSize.width);
        let height = Int(tileSize.height);
        guard let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.stride) else {
            return
        }
        defer {
            free(rawData);
        }

        guard let context = context(for: rawData, width: width, height: height) else {
            return
        }

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = .shaderRead;
        let region = MTLRegionMake2D(0, 0, width, height)
        let bytesPerRow = bytesPerPixel * width

        //We'll create textures, only when there's no texture associated to tile.
        for tile in tiles where tile.isEmpty() {

            let shouldBreak = autoreleasepool {
                if request.isCancelled { return true }

                context.saveGState()

                if let cachedImage = self.cachedImage(noteshelfPage, tileIndex: tile.index) , let imageRef = cachedImage.cgImage {
                    context.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
                } else {
                    let tileRect = tile.rect;

                    context.translateBy(x: 0, y: CGFloat(height));
                    context.scaleBy(x: 1, y: -1)


                    let dx : CGFloat = -tileRect.origin.x
                    let dy : CGFloat = scaledPageSize.height - tileRect.origin.y - tileRect.size.height
                    context.translateBy(x: dx, y: -dy);

                    let midx = CGFloat(scaledPageSize.width)*0.5;
                    let midy = CGFloat(scaledPageSize.height)*0.5;

                    let rotatedAngle: CGFloat = noteshelfPage.invertedRotationAngle()

                    context.translateBy(x: midx, y: midy);
                    context.rotate(by: rotatedAngle.degreesToRadians);
                    if(rotatedAngle == 0 || rotatedAngle == 180) {
                        context.translateBy(x: -midx, y: -midy);
                    } else {
                        context.translateBy(x: -midy, y: -midx);
                    }
                    let templateInfo = noteshelfPage.templateInfo;
                    let drawTransform = drawingTransform(page,
                                                         CGRect(origin: .zero, size: scaledPageSize),
                                                         totalScalefactor,
                                                         pdfBox,
                                                         Int32(rotatedAngle),
                                                         templateInfo.version);

                    context.concatenate(drawTransform);
                    if(documentVersion > 0) {
                        page.displaysAnnotations = templateInfo.renderAnnotations;
                        objc_sync_enter(page)
                        context.fill([context.boundingBoxOfClipPath]);
                        page.draw(with: pdfBox, to: context);
                        context.flush()
                        objc_sync_exit(page)
                    }
                    else {
                        if let pageRef = page.pageRef {
                            context.drawPDFPage(pageRef);
                        }
                    }


                    if FTDeveloperOption.showTileBorder {
                        context.setStrokeColor(UIColor.blue.cgColor)
                        context.stroke(context.boundingBoxOfClipPath, width: 2.0)
                    }

                    if FTDeveloperOption.showTileInfo {
                        let font = UIFont.systemFont(ofSize: 15)
                        let string = NSAttributedString(string: "\(tile.index)", attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: UIColor.blue])
                        UIGraphicsPushContext(context)
                        context.scaleBy(x: 2, y: -2)
                        string.draw(at: context.boundingBoxOfClipPath.origin)
                        UIGraphicsPopContext()
                    }

                    self.saveCacheImage(context.makeImage(), page: noteshelfPage, tileIndex: tile.index);

                }
                guard let texture = mtlDevice.makeTexture(descriptor: textureDescriptor) else {
#if DEBUG
                    fatalError("Unable to create Tiles Texture, DEBUG for the reason.")
#else
                    return false;
#endif
                }
                
                texture.replace(region: region,
                                mipmapLevel: 0,
                                withBytes: rawData,
                                bytesPerRow: bytesPerRow)
                tile.setTexture(texture)

                if let pageWithColor = noteshelfPage as? FTPageBackgroundColorProtocol, noteshelfPage.templateInfo.isTemplate, pageWithColor.pageBackgroundColor == nil {
                    let color = context.colorAt(x: 1, y: 1)
                    pageWithColor.updateBackgroundColor(color: color)
                }
                context.restoreGState();
                return false;
            }
            if(shouldBreak) {
                break;
            }
        }
    }

    private func context(for data: UnsafeMutableRawPointer, width: Int, height: Int) -> CGContext? {

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
        context.setFillColor(UIColor.white.cgColor);
        context.fill(CGRect(origin: .zero, size: CGSize(width: width, height: height)));
        context.interpolationQuality = CGInterpolationQuality.none;
        return context
    }

    private func cacheUrlFor(_ page: FTPageProtocol,tileIndex: Int) -> URL {
        guard let fileName = page.associatedPDFFileName else {
            fatalError("File name cannot be nil")
        }
        let contentSize = "\(Int(self.contentSize.width))x\(Int(self.contentSize.height))"

        let pdfTitle = (page.associatedPDFFileName as NSString?)?.deletingPathExtension ?? "-"
        var key = "\(pdfTitle)_\(page.associatedPDFKitPageIndex)_\(contentSize)"
        let angle = (page.pdfPageRef?.rotation ?? 0) + Int(page.rotationAngle)
        if angle > 0 {
            key += "_\(angle)"
        }

        key += "_\(tileIndex)"

        let cacheImageURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(key)
        return cacheImageURL;
    }

    private func cachedImage(_ page: FTPageProtocol,tileIndex: Int) -> UIImage? {
        if(!FTDeveloperOption.cacheTextureTileImage) {
            return nil
        }
        let cacheURL = cacheUrlFor(page, tileIndex: tileIndex)
        if FileManager().fileExists(atPath: cacheURL.path),
           let image = UIImage(contentsOfFile: cacheURL.path) {
            return image
        }
        return nil;
    }

    private func saveCacheImage(_ image: CGImage?,page: FTPageProtocol,tileIndex: Int) {
        if(!FTDeveloperOption.cacheTextureTileImage) {
            return
        }
        if let img = image, let pngData = UIImage(cgImage: img).pngData() {
            let cacheURL = cacheUrlFor(page, tileIndex: tileIndex)
            try? pngData.write(to: cacheURL, options: .atomic)
        }
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        #if DEBUG
        return UIColor(
           red:   .random(),
           green: .random(),
           blue:  .random(),
           alpha: 1.0
        )
        #else
        return UIColor.white
        #endif
    }
}

///This rect calculation is purely for texture generation purpose. Hence we're not mving this code to common place.
extension FTPageProtocol {
    ///This logic is same as `pdfPageRect` property on top of `FTPageProtocol`.
    func pageRectForRendering() -> CGRect {
        guard let page = self.pdfPageRef else { return CGRect.zero }

        let pdfBox : PDFDisplayBox
        let documentVersion = self.templateInfo.version.floatValue;
        if(documentVersion > Float(0)) {
            pdfBox = PDFDisplayBox.cropBox;
        } else {
            pdfBox = PDFDisplayBox.mediaBox;
        }

        var pageRect = page.bounds(for: pdfBox)
        if (pageRect.size.width == 0 || pageRect.size.height == 0 ) {
            return CGRect.zero;
        }

        let rotatedAngle = invertedRotationAngle()

        if(documentVersion > Float(0)) {
            let trasnform = page.transform(for: pdfBox);
            pageRect = pageRect.applying(trasnform)
            let rotate = CGAffineTransform(rotationAngle: rotatedAngle.degreesToRadians);
            pageRect = pageRect.applying(rotate);
            pageRect.origin = CGPoint.zero;
        }
        else {
            pageRect = page.pageRef!.getBoxRect(CGPDFBox.mediaBox);
            let transform = page.pageRef?.getDrawingTransform(CGPDFBox.mediaBox, rect: pageRect, rotate: Int32(rotatedAngle), preserveAspectRatio: true);
            pageRect = pageRect.applying(transform!);
            pageRect.origin = CGPoint.zero;
        }

        return pageRect
    }

    fileprivate func invertedRotationAngle() -> CGFloat {
        var rotatedAngle = 360 - CGFloat(self.rotationAngle);
        if(rotatedAngle >= 360) {
            rotatedAngle = 360 - rotatedAngle
        }
        return rotatedAngle
    }
}
