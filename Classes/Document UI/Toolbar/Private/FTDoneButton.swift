//
//  FTDoneButton.swift
//  Noteshelf
//
//  Created by Narayana on 21/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

class FTDoneButton: FTBaseButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel?.font = UIFont.appFont(for: .regular, with: 17)
        self.setTitle(NSLocalizedString("Done", comment: "Done"), for: .normal)
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += 1
        return size
    }
}
