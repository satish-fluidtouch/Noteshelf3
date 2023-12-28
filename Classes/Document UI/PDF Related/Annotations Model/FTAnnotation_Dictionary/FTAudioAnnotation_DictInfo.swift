//
//  FTAudioAnnotation_DictInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 15/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTAudioAnnotation {
    override func update(with info: FTAnnotationDictInfo) {
        super.update(with: info);
        self.screenScale = info.value(for: "screenScale") ?? Float(UIScreen.main.scale);
        self.modifiedTimeInterval = info.value(for: "modifiedTime") ?? Date.timeIntervalSinceReferenceDate;
        self.createdTimeInterval = info.value(for: "createdTime") ?? Date.timeIntervalSinceReferenceDate;
    }
}
