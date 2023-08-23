//
//  FTSettingsBaseTableViewCell.swift
//  Noteshelf
//
//  Created by Paramasivan on 25/10/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTSettingsBaseTableViewCell: UITableViewCell {
    
    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var imageViewIcon: UIImageView?
    @IBOutlet weak var labelTitle: FTSettingsLabel?
    @IBOutlet weak var labelSubTitle: FTSettingsLabel?
    @IBOutlet weak var `switch`: UISwitch?
    @IBOutlet weak var rightSideDetailLabel: FTSettingsLabel?
    @IBOutlet weak var backUpOptionImageview: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.rightSideDetailLabel?.fontStyle = FTSettingFontStyle.rightOption.rawValue
        self.applySelectionStyleGray();
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let accessoryView = self.accessoryView {
            var accessoryViewFrame = accessoryView.frame
            accessoryViewFrame.origin.x = self.bounds.width - accessoryViewFrame.width;
            accessoryView.frame = accessoryViewFrame;
        }
    }
    
    func setEnable(_ status: Bool) {
        self.accessibilityTraits = status ? UIAccessibilityTraits.none : UIAccessibilityTraits.notEnabled;
        self.isUserInteractionEnabled = status
        self.enableSubviews(status,forView: self);
    }
    
    fileprivate func enableSubviews(_ status: Bool,forView view:UIView) {
        for eachView in view.subviews {
            if let control = eachView as? UIControl {
                control.isEnabled = status
            }
            else if let label = eachView as? FTStyledLabel {
                label.isEnabled = status
            }
            else if let control = eachView as? UIImageView {
                control.alpha = status ? 1 : 0.4;
            }
            else if let label = eachView as? UILabel {
                label.alpha = status ? 1 : 0.4;
                label.isEnabled = status
            }
            else {
                self.enableSubviews(status,forView: eachView);
            }
        }
    }
    
    func applySelectionStyleGray() {
        let backgroundView = UIView(); 
        backgroundView.backgroundColor = UIColor.appColor(.black5)
        self.selectedBackgroundView = backgroundView;
    }
}

class FTSettingsBckupFormatTableViewCell: FTSettingsBaseTableViewCell {
    @IBOutlet weak var formatOptions: UIButton?;
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.formatOptions?.setTitle(FTUserDefaults.backupFormat.displayTitle, for: .normal);

        let menuItem = UIDeferredMenuElement.uncached({ [weak self] items in
            var menuItems = [UIMenuElement]();
            let currentItem = FTUserDefaults.backupFormat;
            FTCloudBackupFormat.allCases.forEach { eachItem  in
                let action = UIAction(title: eachItem.displayTitle,state: (eachItem == currentItem) ? .on : .off) { action in
                    FTUserDefaults.backupFormat = eachItem;
                    self?.formatOptions?.setTitle(eachItem.displayTitle, for: .normal);
                }
                menuItems.append(action);
            }
            items(menuItems)
        });
        
        self.formatOptions?.menu = UIMenu(children: [menuItem]);
        self.formatOptions?.showsMenuAsPrimaryAction = true;
    }
}
