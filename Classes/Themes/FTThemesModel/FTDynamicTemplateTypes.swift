//
//  FTDynmaicTemplateTypes.swift
//  FTTemplatePicker
//
//  Created by Sameer on 28/07/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import PDFKit
import FTCommon
import FTNewNotebook

class FTAutoTemlpateDiaryTheme : FTPaperTheme {
    var templateId: FTTemplateID = .digitalDiariesClassic
    var startDate: Date?
    var endDate: Date?
    var diaryStartYear : Int?
    var weekFormat : FTWeekFormat = .Sunday

    override init(url : URL,metaData : NSDictionary) {
        super.init(url: url, metaData: metaData)

        if let year = metaData.value(forKey: "startYear") as? String {
            self.diaryStartYear = Int(year)
        }
        if let templateIdValue = metaData.value(forKey: "template_id") as? String, let templateId = FTTemplateID(rawValue: templateIdValue) {
            self.templateId = templateId
        }
    }

    override func themeTemplateURL() -> URL {
        return URL(string: "FTNAutoTemlpateDiaryTheme_template")!
    }
}

class FTDynamicTemplateTheme: FTPaperTheme,FTPaperThumbnailGenerator {
    var templateInfoDict: NSDictionary?

    override init(url : URL,metaData : NSDictionary) {
        super.init(url: url, metaData: metaData)

        if let dict = metaData.value(forKey: "dynamic_template_info") as? NSDictionary {
            self.templateInfoDict = dict
        }
    }

    override func themeThumbnail() -> UIImage {
        var key = ""
        if let variants = self.customvariants {
            let orientation = (variants.isLandscape) ? FTDeviceOrientation.land : FTDeviceOrientation.port
            key = self.displayName + "_" +  (variants.lineType.lineType.rawValue) + "_" + (variants.selectedColor.colorName.rawValue) + "_" + orientation.rawValue
            key += "_" + (variants.selectedDevice.dimension)
        }
        if let image = getImageFromDirectory(key) {
            return image
        } else {
            let thumbURL = self.themeThumbnailURL(variants: self.customvariants);
            if let image =  UIImage.init(contentsOfFile: thumbURL.path){
                return image
            }
            return getDefaultPaperImage()
        }

    }
    @available(*, renamed: "generateThumbnail(theme:)")
    override func generateThumbnail(theme: FTThemeable, completionhandler: @escaping (UIImage?) -> ()) {
        Task {
            let result = await generateThumbnail(theme: theme)
            completionhandler(result)
        }
    }

    override func generateThumbnailFor(selectedVariantsAndTheme: FTSelectedPaperVariantsAndTheme,forPreview:Bool, completionhandler: @escaping (UIImage?) -> ())  {
        Task {
            var paperVariants = FTBasicTemplatesDataSource.shared.fetchSelectedVaraintsForMode(.basic)
            let basicTemplateColors = FTBasicTemplatesDataSource.shared.getTemplateSizeData().first(where: {$0.size == selectedVariantsAndTheme.size})
            let deviceModel: FTDeviceModel?
            if selectedVariantsAndTheme.size == .iPad || selectedVariantsAndTheme.size == .mobile {
                deviceModel = FTBasicTemplatesDataSource.shared.getDeviceModelForIPadOrMobile(selectedVariantsAndTheme.size)
            } else {
                deviceModel = FTBasicTemplatesDataSource.shared.getDeviceDataFor(templateSize: selectedVariantsAndTheme.size)
            }
            if let lineType =  FTBasicTemplatesDataSource.shared.getLineTypeFor(lineHeight: selectedVariantsAndTheme.lineHeight),
                let templateColor = FTBasicTemplatesDataSource.shared.getTemplateColorFor(templateColorModel: selectedVariantsAndTheme.templateColorModel),
                var deviceModel {
                if !forPreview {
                    deviceModel = FTDeviceDataManager().standardiPadDevice
                }
                paperVariants = FTSelectedVariants(lineType: lineType, selectedDevice: deviceModel, isLandscape: selectedVariantsAndTheme.orientation.isLandscape, selectedColor: templateColor)
            }
            let result = await self.generateThumbnailFor(theme: selectedVariantsAndTheme.theme, variants: paperVariants)
            completionhandler(result)
        }
    }
    override func generateThumbnail(theme: FTThemeable) async -> UIImage? {
        await self.generateThumbnailFor(theme: theme, variants: self.customvariants)
    }
    private func generateThumbnailFor(theme:FTThemeable,variants:FTPaperVariants?) async -> UIImage? {
        guard let variants = variants else {
            return nil
        }
        self.customvariants = variants
        let orientation = (variants.isLandscape) ? FTDeviceOrientation.land : FTDeviceOrientation.port
        var key = theme.displayName + "_" +  (variants.lineType.lineType.displayTitle) + "_" + (variants.selectedColor.colorHex) + "_" + orientation.rawValue
        key += "_" + (variants.selectedDevice.dimension)

        let imageToReturn: UIImage?

        if let cachedImage = getImageFromDirectory(key) {
            imageToReturn = cachedImage
        } else if let theme = theme as? FTTheme {
            let generator = FTAutoTemplateGenerator.autoTemplateGenerator(theme: theme, generationType: .thumbnail)
            do {
                let docInfo = try await generator.generate()
                  if let url = docInfo.inputFileURL {
                    let img = try await self.drawPDFfromURL(url: url)
                    self.saveImageToDocumentDirectory(image: img, key)
                    imageToReturn = img
                } else {
                    imageToReturn = nil
                }
            } catch {
                imageToReturn = nil
            }
        } else {
            imageToReturn = nil
        }
        return imageToReturn
    }
    override func themeTemplateURL() -> URL {
        return URL(string: "FTNDynamicTemlpateDiaryTheme_template")!
    }
}

class FTStretchTemplateTheme: FTPaperTheme {
    var backgroundColor: String = "#F7F7F2-1.0";

    override init(url : URL,metaData : NSDictionary) {
        super.init(url: url, metaData: metaData)
        if let bgColor = metaData["bgColor"] as? String {
            self.backgroundColor = bgColor;
        }
    }

    override func themeTemplateURL() -> URL {
        var templateURL : URL?;
        let templateKey = self.customvariants!.isLandscape ? "template_\(FTDeviceOrientation.land.rawValue).pdf" : "template_\(FTDeviceOrientation.port.rawValue).pdf"
        let pdfTemplate = self.themeFileURL.appendingPathComponent(templateKey);
        let packageTemplate = self.themeFileURL.appendingPathComponent("template.noteshelf");

        let pdfTemplateDeviceSpecific = self.themeFileURL.appendingPathComponent(self.deviceSpecificTemplateName());

        if(FileManager.default.fileExists(atPath: pdfTemplateDeviceSpecific.path)) {
            templateURL = pdfTemplateDeviceSpecific;
        } else if(FileManager.default.fileExists(atPath: pdfTemplate.path)) {
            templateURL = pdfTemplate;
        } else if(FileManager.default.fileExists(atPath: packageTemplate.path)) {
            templateURL = packageTemplate;
        }

        if templateURL == nil {
            //TODO:- Reset to default pdf
            templateURL = self.themeFileURL.appendingPathComponent("template_iPad_port.pdf")
        }

        return templateURL!;
    }

    override func preview() async -> UIImage? {
        do {
            let previewImage = try await self.drawPDFfromURL(url: self.themeTemplateURL())
            return previewImage
        }
        catch {
            fatalError("Preview failure")
        }
    }

    override func generateThumbnail(theme: FTThemeable, completionhandler: @escaping (UIImage?) -> ()) {
        let url =  self.themeThumbnailURL(variants: self.customvariants)
        if let image = UIImage.init(contentsOfFile: url.path){
            completionhandler(image)
        }
        completionhandler(getDefaultPaperImage())
    }

    override func themeThumbnail() -> UIImage {
        let url =  self.themeThumbnailURL(variants: self.customvariants)
        if let image = UIImage.init(contentsOfFile: url.path){
            if self.customvariants.isLandscape && shouldGenerateThumbnailFor(image: image){
                return generateLandscapeThumbnail()
            }
            return image
        }
        return getDefaultPaperImage()
    }

    private func generateLandscapeThumbnail() -> UIImage{
        if let variants = self.customvariants {
            let key = self.displayName + "_" + (variants.selectedDevice.dimension)
            if let cachedImage = getImageFromDirectory(key) {
                return cachedImage
            } else {
                let templateKey = "template_\(FTDeviceOrientation.land.rawValue).pdf"
                let pdfTemplateURL = self.themeFileURL.appendingPathComponent(templateKey);
                if let pdfDocument = PDFDocument(url: pdfTemplateURL) {
                    let thumbImage = generateThumbImage(pdfDocument, withSize: self.getDeviceDemension().size)
                    self.saveImageToDocumentDirectory(image: thumbImage, key)
                    return thumbImage
                }
            }
        }
        return getDefaultPaperImage()
    }

    private func getDeviceDemension() -> CGRect{
        let measurements = self.customvariants.selectedDevice.dimension_land.split(separator: "_")
        let width = Int(measurements[0])
        let height = Int(Double(measurements[1])!)
        return CGRect(x: 0, y: 0, width: width!, height: height)
    }

    private func generateThumbImage(_ pdfDocument : PDFDocument, withSize size: CGSize) -> UIImage
    {
        let pageBox = PDFDisplayBox.cropBox;

        let page : PDFPage = pdfDocument.page(at: 0)!;
        var mediaBox = page.bounds(for: pageBox);

        let trasnform = page.transform(for: pageBox);
        mediaBox = mediaBox.applying(trasnform);

        mediaBox.origin = CGPoint.zero;

        let thumbnailSize = size;

        let pageRect = FTCommonUtils.aspectFit(mediaBox, targetRect: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height));
        let image = page.thumbnail(of: pageRect.size, for: pageBox);
        return image;
    }

    fileprivate func shouldGenerateThumbnailFor(image : UIImage) -> Bool {
        //here 180 is hardcode as required width for the display of thumbnail as per new design should be 180 where as in older version this image width was 137. Hence in order to decide if the image needs to be generated or not, we are depending on this condition.
        if image.size.width != 180 {
            return true
        }
        return false
    }

    fileprivate func deviceSpecificTemplateName() -> String {
        let deviceSpecificKey = UIDevice.deviceSpecificKey();
        return "template_\(deviceSpecificKey).pdf"
    }
}
