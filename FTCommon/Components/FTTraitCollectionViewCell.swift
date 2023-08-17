//
//  FTTRaitCollectionViewCell.swift
//  FTCommon
//
//  Created by Narayana on 13/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

open class FTTraitCollectionViewCell: UICollectionViewCell {
    public var isRegular: Bool {
        var status = self.traitCollection.isRegular
        if nil != self.window {
            status = self.isRegularClass()
        }
        return status
    }
}
