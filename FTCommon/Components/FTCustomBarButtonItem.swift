//
//  FTCustomBarButtonItem.swift
//  FTCommon
//
//  Created by Siva on 25/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

final class FTCustomBarButtonItem: UIBarButtonItem {
    @IBInspectable var localizationKey: String?
    override func awakeFromNib() {
        super.awakeFromNib()
        if let localizationKey = self.localizationKey {
            title =  NSLocalizedString(localizationKey, comment: self.title ?? "")
        } else {
            title = title?.localized
        }
    }
}

