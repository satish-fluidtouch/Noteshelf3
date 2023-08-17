//
//  FTRightDetailTableViewCell.swift
//  Noteshelf
//
//  Created by Siva on 15/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTRightDetailTableViewCell: FTExportBaseTableViewCell {
    
    @IBOutlet weak var labelTopLine: FTStyledLabel!
    @IBOutlet weak var labelTitle: FTStyledLabel!
    @IBOutlet weak var labelSubTitle: FTStyledLabel!
    @IBOutlet fileprivate weak var accessoryViewImage: UIImageView!
    @IBOutlet weak var labelBottomLine: FTStyledLabel!
    @IBOutlet weak var textviewSubDetailEditable: UITextView?
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
