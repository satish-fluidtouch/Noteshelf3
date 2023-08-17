//
//  FTStoreCategoryTableViewCell.swift
//  Noteshelf
//
//  Created by Anil Saini on 12/03/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTStoreCategoryTableViewCell: UITableViewCell {

    @IBOutlet weak var imgClubIcon: UIImageView!
    @IBOutlet weak var lblClubTitle: UILabel!
    
    override func awakeFromNib() {
        self.applySelectionStyleGray();
        self.layoutIfNeeded();
    }
    
    func applySelectionStyleGray() {
        let backgroundView = UIView();
        backgroundView.backgroundColor = UIColor(white: 1, alpha: 0.1);
        self.selectedBackgroundView = backgroundView;
    }
}
