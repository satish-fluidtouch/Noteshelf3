//
//  FTImageAnnotation_DictInfo.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 15/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension FTImageAnnotation {
    override func update(with info: FTAnnotationDictInfo) {
        super.update(with: info);

        self.screenScale = info.value(for: "screenScale") ?? UIScreen.main.scale;
        self.transformMatrix = info.trasnform(for:"txMatrix")
        self.imageTransformMatrix = info.trasnform(for:"imgTxMatrix")
    }
}

extension FTWebClipAnnotation {
    override func update(with info: FTAnnotationDictInfo) {
        super.update(with: info)
        self.clipString = info.value(for: "clipString") ?? ""
    }
}

extension FTStickyAnnotation {
    override func update(with info: FTAnnotationDictInfo) {
        super.update(with: info)
        self.emojiName = info.value(for: "emojiName") ?? ""
    }
}
