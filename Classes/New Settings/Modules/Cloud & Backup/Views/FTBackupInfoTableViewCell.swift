//
//  FTBackupInfoTableViewCell.swift
//  Noteshelf
//
//  Created by Matra on 15/02/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTBackupInfoTableViewCell: FTSettingsBaseTableViewCell {

    @IBOutlet weak var blueView: UIView?
    @IBOutlet private weak var containerView: UIView?
    @IBOutlet weak var imageIconLeadingConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.containerView?.layer.cornerRadius = 4.0
        self.blueView?.layer.cornerRadius = (blueView?.bounds.height)! / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        if selected {
            self.blueView?.backgroundColor = UIColor.appColor(.accent);
            self.containerView?.backgroundColor = .clear
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated);
        // Configure the view for the Highlighted state
        if highlighted {
            self.blueView?.backgroundColor = UIColor.appColor(.accent);
            self.containerView?.backgroundColor = .clear
        }
    }
}
