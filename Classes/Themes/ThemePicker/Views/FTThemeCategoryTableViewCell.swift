//
//  FTThemeCategoryTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 21/04/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTThemeCategoryTableViewCell: UITableViewCell {
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var blueDotView: UIView!
    
    override func awakeFromNib() {
        self.applySelectionStyleGray();
        blueDotView.layer.cornerRadius = blueDotView.bounds.width/2
        self.layoutIfNeeded();
    }
    
    func applySelectionStyleGray() {
        let backgroundView = UIView();
        backgroundView.backgroundColor = UIColor.appColor(.black5)
        self.selectedBackgroundView = backgroundView;
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            self.titleLabel.textColor = UIColor.label
        }
    }
}
