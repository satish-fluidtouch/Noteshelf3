//
//  FTAdvancedTableViewController.swift
//  Noteshelf
//
//  Created by Matra on 16/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

class FTAdvancedViewController: UIViewController {
    
    @IBOutlet weak var otherSettingsInfoLabel: UILabel!
    @IBOutlet weak var lockPwdInfoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let imgText = NSMutableAttributedString(string: "")
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "desk_tool_optionsLight")?.withTintColor(.headerColor)
        attachment.bounds = CGRect.init(x: 0, y: -5, width: 22.0, height: 22.0)
        let imgStr = NSAttributedString(attachment: attachment)
        imgText.append(imgStr)
        
        let localStr = String(format: NSLocalizedString("Advanced_OtherSettingsInfo", comment: "info"))
        let infoStr = NSMutableAttributedString(string: localStr, attributes: [NSAttributedString.Key.font: UIFont.appFont(for: .regular, with: 16)])
        infoStr.replaceCharacters(in: (localStr as NSString).range(of: "?"), with: imgText)
                                             
        self.otherSettingsInfoLabel.attributedText = infoStr 
        self.lockPwdInfoLabel.text = NSLocalizedString("Advanced_LockSettingsInfo", comment: "info")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar(title: NSLocalizedString(FTSettingsOptions.advanced.rawValue, comment: ""))
    }
  
}
