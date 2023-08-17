//
//  FTProgressTableViewCell.swift
//  Noteshelf
//
//  Created by Matra on 23/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTProgressTableViewCell: UITableViewCell {

    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var labelInfo: FTStyledLabel!
    @IBOutlet weak var labelUserID: FTStyledLabel!
    @IBOutlet weak var progressView: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.progressContainerView.layer.cornerRadius = 4.0
    }

}
