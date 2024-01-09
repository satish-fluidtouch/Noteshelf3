//
//  FTTextAnnotation_DictInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 15/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTTextAnnotation {
    override func update(with info: FTAnnotationDictInfo) {
        super.update(with: info);
        
        self.transformScale = info.value(for: "transformScale") ?? 1;
        if self.transformScale <= 0 {
            self.transformScale = 1;
        }
        self.rotationAngle = info.value(for: "rotationAngle") ?? 0;
        
        if let value: Data = info.value(for: "attrText") {
            self.dataValue = value;
        }
    }
}
