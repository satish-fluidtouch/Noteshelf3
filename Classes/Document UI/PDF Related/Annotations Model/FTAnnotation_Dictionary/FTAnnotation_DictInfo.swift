//
//  FTAnnotation_Dictionary.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 15/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTAnnotation {
    static func annotation(_ info: FTAnnotationDictInfo) -> FTAnnotation? {
        var annotation : FTAnnotation?
        let annotationType = info.annotationType;
        switch(annotationType) {
        case .stroke:
            annotation = FTStroke();
        case .image:
            annotation = FTImageAnnotation();
        case .sticky:
            annotation = FTStickyAnnotation();
        case .text:
            annotation = FTTextAnnotation();
        case .audio:
            annotation = FTAudioAnnotation();
        case .shape:
            annotation = FTShapeAnnotation();
        case .fancyTitle:
            debugPrint("Implement this")
        case .sticker:
            annotation = FTStickerAnnotation();
        case .webclip:
            annotation = FTWebClipAnnotation();
        case .none:
            break;
        default:
            fatalError("Should not enter here");
        }
        annotation?.update(with: info);
        return annotation;
    }
    
    @objc func update(with info:FTAnnotationDictInfo) {
        self.uuid = info.value(for: "id") ?? UUID().uuidString;
        self.boundingRect = info.boundingRect

        self.isReadonly = info.value(for: "isReadonly") ?? false
        self.version = info.value(for: "version") ?? 1;
        self.isLocked = info.value(for: "isLocked") ?? false
    }
}
