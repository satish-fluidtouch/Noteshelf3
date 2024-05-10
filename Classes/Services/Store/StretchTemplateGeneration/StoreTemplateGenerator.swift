//
//  StretchTemplateGenerator.swift
//  FTTemplatePicker
//
//  Created by Sameer on 03/08/20.
//  Copyright © 2020 Mahesh. All rights reserved.
//

import Foundation

class FTStoreTemplateGenerator: NSObject {
    private var templateFormat: FTStoreTemplateFormat;

    init(theme: FTStoreTemplatePaperTheme) {
        guard let variants = theme.customvariants else {
            fatalError("variants missing");
        }
        self.templateFormat = FTStoreTemplateFormat(variants.isLandscape, variants,
                                                           templateUrl: theme.themeFileURL);
        self.templateFormat.bgColor = variants.selectedColor.colorHex;
    }

    func generate() -> URL {
        let templateURL = self.rootPath.appendingPathComponent(templateFormat.templateUrl.lastPathComponent)
        UIGraphicsBeginPDFContextToFile(templateURL.path, templateFormat.outerRect, nil)
        if let context = UIGraphicsGetCurrentContext() {
            templateFormat.renderTemplate(context: context)
        }
        UIGraphicsEndPDFContext()

        return templateURL
    }

    var rootPath: URL {
        let tempPath = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent("com.ns3.temp")
        if !FileManager.default.fileExists(atPath: tempPath.path) {
             try? FileManager.default.createDirectory(at: tempPath, withIntermediateDirectories: true)
            return tempPath
        }
        return tempPath
    }
}

