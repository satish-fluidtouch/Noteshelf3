//
//  FTPaperTheme.swift
//  FTTemplatePicker
//
//  Created by Sameer on 27/07/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import UIKit
import FTNewNotebook
import QuickLookThumbnailing

let previewImageCache = NSCache<NSString, UIImage>()

protocol FTPaperVariants {
    var lineType: FTLineType {get set}
    var selectedDevice: FTDeviceModel {get set}
    var isLandscape: Bool {get set}
    var selectedColor: FTThemeColors {get set}
}

enum FTDeviceOrientation: String {
    case port
    case land
}

enum ImageGenerationError: Error {
    case invalidPath
}

class FTPaperTheme: FTTheme, FTPaperThemeable {
    var recentVariants: FTPaperVariants!
    var lineHeight : Int?;
    var standardDiaryStartYear : Int?
    var customvariants: FTPaperVariants!

    static func paperTheme(url: URL) -> FTPaperTheme? {
        var themeObj : FTPaperTheme?
        let metaDataURL = url.appendingPathComponent("metadata.plist");
        if FileManager.default.fileExists(atPath: metaDataURL.standardizedFileURL.path), let metaData = NSDictionary(contentsOf: metaDataURL) {
            if let dynamicId = (metaData.value(forKey: "dynamic_id") as? Int) {
                if dynamicId == 1 {
                    themeObj = FTAutoTemlpateDiaryTheme(url: url, metaData: metaData);
                } else if dynamicId == 2 {
                    themeObj = FTDynamicTemplateTheme(url: url, metaData: metaData);
                } else if dynamicId == 3 {
                    themeObj = FTStretchTemplateTheme(url: url, metaData: metaData)
                }
            } else {
                themeObj = FTPaperTheme(url: url);
            }
            if let restrictsChangeTemplateStatus = (metaData.value(forKey: "restrictsChangeTemplate") as? Bool){
                themeObj?.restrictsChangeTemplate = restrictsChangeTemplateStatus
            }
            if let themeObj = themeObj {
                if let line_height = metaData.value(forKey: "line_height") as? Int, line_height > 0 {
                    themeObj.lineHeight = line_height;
                }
                if let year = metaData.value(forKey: "startYear") as? String {
                    themeObj.standardDiaryStartYear = Int(year)
                }
                return themeObj
            }
        }
        return FTPaperTheme(url: url)
    }

    override init(url: URL) {
        super.init(url: url);
    }

    init(url : URL,metaData : NSDictionary) {
        super.init(url: url);
    }

    func setPaperVariants(_ variants: FTPaperVariants?) {
        self.customvariants = variants
    }

    //MARK:- FTTheme methods implementation
    override  func themeTemplateURL() -> URL {
        var templateURL : URL?;
        let pdfTemplate = self.themeFileURL.appendingPathComponent("template.pdf");
        let packageTemplate = self.themeFileURL.appendingPathComponent("template.noteshelf");

        let pdfTemplateDeviceSpecific = self.themeFileURL.appendingPathComponent(self.deviceSpecificTemplateName());

        if(FileManager.default.fileExists(atPath: pdfTemplateDeviceSpecific.path)) {
            templateURL = pdfTemplateDeviceSpecific;
        } else if(FileManager.default.fileExists(atPath: pdfTemplate.path)) {
            templateURL = pdfTemplate;
        } else if(FileManager.default.fileExists(atPath: packageTemplate.path)) {
            templateURL = packageTemplate;
        }

        return templateURL!;
    }

    fileprivate func deviceSpecificTemplateName() -> String {
        let deviceSpecificKey = UIDevice.deviceSpecificKey();
        return "template_\(deviceSpecificKey).pdf"
    }

    override func themeThumbnail() -> UIImage {
        let thumbURL = self.themeThumbnailURL(variants: self.customvariants);
        if let image = UIImage.init(contentsOfFile: thumbURL.path){
            return image
        }
        return getDefaultPaperImage()
    }

    override func preview() -> UIImage? {
        if self.isCustom {
            do {
                let previewImage = try self.drawPDFfromURL(url: self.themeTemplateURL())
                return previewImage
            }
            catch {
                return nil
            }
        } else if let variants = self.customvariants {
            let orientation = (variants.isLandscape) ? FTDeviceOrientation.land : FTDeviceOrientation.port
            var key = self.displayName + "_" +  (variants.lineType.lineType.rawValue) + "_" + (variants.selectedColor.colorName.rawValue) + "_" + orientation.rawValue
            key += "_" + (variants.selectedDevice.dimension)
            if let cachedImage = previewImageCache.object(forKey: key as NSString) {
                return cachedImage
            } else {
                let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme: self, generationType: .preview)
                do {
                    let doct = generator.generate()
                    if let inputUrl = doct.inputFileURL {
                        let previewImage = try self.drawPDFfromURL(url: inputUrl)
                        previewImageCache.setObject(previewImage, forKey: key as NSString)
                        return previewImage
                    }
                    return nil
                } catch {
                    return nil
                }
            }
        } else {
            return nil
        }
    }

    override func isValidTheme() -> Bool {
        let templateURL = self.themeFileURL.appendingPathComponent("template.pdf");
        var fileExisits = FileManager().fileExists(atPath: templateURL.path);

        if !fileExisits {
            let templateURL = self.themeFileURL.appendingPathComponent("template.noteshelf");
            fileExisits = FileManager().fileExists(atPath: templateURL.path);
        }
        if !fileExisits{
            fileExisits = self.dynamicId != 0
        }
        return fileExisits;
    }

    func generateThumbnailFor(selectedVariantsAndTheme: FTSelectedPaperVariantsAndTheme,forPreview:Bool) -> UIImage? {
        return UIImage(named: "")
    }

    func generateThumbnail(theme: FTThemeable) -> UIImage? {
        return UIImage(named: "")
    }

    func themeThumbnailURL(variants: FTPaperVariants?) -> URL {
        var thumbURL : URL?;
        if self.isCustom {
            thumbURL = self.themeFileURL.screenScaleURL(for: "thumbnail.png");
        } else if let selectedVariants = variants as? FTSelectedVariants {
            let key = selectedVariants.getThumbKey()
            thumbURL = self.themeFileURL.screenScaleURL(for: key);
        }
        return getThumbURLIfPresentAt(url: thumbURL)
    }
    func getThumbURLIfPresentAt(url :URL?) -> URL{
        guard let thumbURL = url, FileManager.default.fileExists(atPath: thumbURL.path) else {
            return getDefaultPaperURL()
        }
        return thumbURL
    }

    func drawPDFfromURL(url: URL) throws -> UIImage {
        guard let document = CGPDFDocument(url as CFURL) else {
            throw ImageGenerationError.invalidPath
        }

        guard let page = document.page(at: 1) else {
            throw ImageGenerationError.invalidPath
        }

        let pageRect = page.getBoxRect(.cropBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let img = renderer.image { ctx in
            UIColor.white.set()
            ctx.cgContext.interpolationQuality = .high
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            ctx.cgContext.drawPDFPage(page)
        }
        return img
    }

    func getDefaultPaperImage() -> UIImage{
        let defaultImagePath = Bundle.main.url(forResource: "default_paper_image", withExtension: "png")
        return UIImage(contentsOfFile: defaultImagePath!.path)!
    }

    func getDefaultPaperURL() -> URL{
        if let url = Bundle.main.url(forResource: "default_paper_image", withExtension: "png"){
            return url;
        }
        else{
            fatalError("Default paper image not found in bundle")
        }
    }

    //MARK:- Generated thumbnails saving and retrieving
    var thumbnailPath : URL {
        let rootPathURL = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent("ThumbImages");
        let fileManager = FileManager();
        if(!fileManager.fileExists(atPath: rootPathURL.path)) {
            try? fileManager.createDirectory(at: rootPathURL, withIntermediateDirectories: true, attributes: nil);
        }
        return rootPathURL;
    };

    func saveImageToDocumentDirectory(image: UIImage, _ key: String ) {
        let documentsDirectory =  self.thumbnailPath
        let fileName = key + ".png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        if let data = image.pngData(),!FileManager.default.fileExists(atPath: fileURL.path){
            do {
                try data.write(to: fileURL, options: NSData.WritingOptions.atomicWrite)
            } catch {
#if DEBUG
                print("error saving file:", error)
#endif
            }
        }
    }

    func getImageFromDirectory(_ key: String) -> UIImage? {
        let documentsDirectory =  self.thumbnailPath
        let fileName = key + ".png" // name of the image to be saved
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        if  let data = FileManager.default.contents(atPath: fileURL.path) {
            return UIImage.init(data: data)
        }
        return nil
    }
}

class FTStoreTemplatePaperTheme: FTPaperTheme {
    override init(url: URL) {
    super.init(url: url, metaData: NSDictionary())
  }

  override var dynamicId: Int {
    get {
      return FTTemplateType.storeTemplate.rawValue;
    }
    set {}
  }

  override func themeTemplateURL() -> URL {
    return themeFileURL;
  }
}
