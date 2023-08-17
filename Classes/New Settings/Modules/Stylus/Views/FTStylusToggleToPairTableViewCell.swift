//
//  FTStylusToggleToPairTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 15/11/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTStylusToggleToPairTableViewCell: FTSettingsBaseTableViewCell {

    @IBOutlet weak var switchActive: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateEnableText(stylus: FTStylusPenSettingsProtocol) {
        var text = "Enable"
        switch stylus {
        case is FTStylusPenApplePencil:
            text = "settings.useApplePencil"
        default:
            break
        }
        self.labelTitle?.text = text.localized
    }
}
