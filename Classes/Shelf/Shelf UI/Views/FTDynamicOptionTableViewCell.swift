//
//  FTDynamicOptionTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 07/06/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDynamicOptionTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        self.applySelectionStyleGray();
        self.layoutIfNeeded();
    }
    
    func applySelectionStyleGray() {
        let backgroundView = UIView();
        backgroundView.backgroundColor = UIColor.appColor(.black5)
        self.selectedBackgroundView = backgroundView;
    }

    override var canBecomeFocused: Bool {
        return false
    }
}
