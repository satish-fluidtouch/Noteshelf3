//
//  FTPresetsStyleCell.swift
//  Noteshelf
//
//  Created by Mahesh on 31/10/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTPresetsStyleCell: UITableViewCell {
    
    @IBOutlet private weak var borderView: UIView?
    @IBOutlet private weak var presetNameLbl: FTCustomLabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let bgColor = (selected == true) ? UIColor.appColor(.accentBg) : UIColor.appColor(.cellBackgroundColor)
        let borderColor = (selected == true) ? UIColor.appColor(.accentBg) : UIColor.appColor(.cellBackgroundColor)
        self.borderView?.backgroundColor = bgColor
        self.borderView?.layer.borderWidth = 1.0
        self.borderView?.layer.borderColor = borderColor.cgColor
    }
    
    func updatePresetWithStyle(_ style: FTTextStyleItem) {
        let attribute = NSMutableAttributedString(string: style.displayName)
        self.presetNameLbl?.attributedText = attribute.getFormattedAttributedStringFrom(style: style)
    }
}
