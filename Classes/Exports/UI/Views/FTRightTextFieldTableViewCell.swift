//
//  FTRightTextFieldTableViewCell.swift
//  Noteshelf
//
//  Created by Ramakrishna on 20/10/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

class FTRightTextFieldTableViewCell: FTExportBaseTableViewCell {
    
    @IBOutlet weak var fileNameTextFieldWidthConstarint: NSLayoutConstraint?
    @IBOutlet weak var fileNameTextfield: UITextField?
    @IBOutlet weak var labelTopLine: FTStyledLabel!
    @IBOutlet weak var labelTitle: FTStyledLabel!
    @IBOutlet weak var labelSubTitle: FTStyledLabel!
    @IBOutlet fileprivate weak var accessoryViewImage: UIImageView!
    @IBOutlet weak var labelBottomLine: FTStyledLabel!
    
    @IBOutlet var constraint_Trailing_LabelSubTitle_WithAccessory: NSLayoutConstraint!
    @IBOutlet var constraint_Trailing_LabelSubTitle_WithoutAccessory: NSLayoutConstraint!
    
    override func awakeFromNib() {
        self.updateSubTitleConstraint();
        self.backgroundColor = UIColor.clear;
    }
    
    func hideAccessoryView(_ status: Bool) {
        runInMainThread {
            self.accessoryViewImage.isHidden = status;
            self.updateSubTitleConstraint();
        };
    }

    fileprivate func updateSubTitleConstraint() {
        self.setNeedsUpdateConstraints();
        self.layoutIfNeeded();
    }
}
