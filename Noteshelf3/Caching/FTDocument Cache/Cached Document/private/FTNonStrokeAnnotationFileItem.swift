//
//  FTNonStrokeAnnotationFileItem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTNonStrokeAnnotationFileItem: FTFileItemPlist {
    func searchForTextAnnotation(contains key: String) -> [FTAnnotation] {
        var annotations = [FTAnnotation]();
        let lowercasedKey = key.lowercased();

        let annotationsInfo = self.annotationsInfo();
        annotationsInfo.forEach { eachItem in
            if eachItem.annotationType == .text
                ,eachItem.nonAttrText.lowercased().contains(lowercasedKey)
                ,let annotation = FTAnnotation.annotation(eachItem) {
                annotations.append(annotation);
            }
        }
        return annotations;
    }

    func annotations(types: [FTAnnotationType]) -> [FTAnnotation] {
        var annotations = [FTAnnotation]();
        let annotationsInfo = self.annotationsInfo();
        annotationsInfo.forEach { eachItem in
            if types.contains(eachItem.annotationType)
                ,let annotation = FTAnnotation.annotation(eachItem) {
                annotations.append(annotation);
            }
        }
        return annotations;
    }

    private func annotationsInfo() -> [FTAnnotationDictInfo] {
        var info = [FTAnnotationDictInfo]();
        let pathString = self.fileItemURL.path(percentEncoded: false)
        if FileManager().fileExists(atPath: pathString) {
            do {
                let data = try Data(contentsOf: self.fileItemURL);
                let contents = try PropertyListSerialization.propertyList(from: data, format: nil)
                if let annotationsInfo = contents as? [FTAnnotationDictInfo] {
                    info = annotationsInfo;
                }
            }
            catch {
                
            }
        }
        return info;
    }
    
    override func saveContentsOfFileItem() -> Bool {
        return true;
    }
}
