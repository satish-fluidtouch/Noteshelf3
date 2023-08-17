//
//  FTExportDataInfoCell.swift
//  Noteshelf
//
//  Created by Narayana on 25/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTExportDataInfoCell: UITableViewCell {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var formatImageView: UIImageView!
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var formatView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.formatView.layer.cornerRadius = 8.0
    }

}
