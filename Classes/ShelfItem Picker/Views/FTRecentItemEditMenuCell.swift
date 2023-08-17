//
//  FTRecentItemEditMenuCell.swift
//  Noteshelf
//
//  Created by Akshay on 11/10/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTRecentItemEditMenuCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        let view = UIView()
        view.backgroundColor = UIColor.appColor(.black5)
        selectedBackgroundView = view
    }
    
    func configure(with menu:FTRecentEditMenuItem) {
        
        switch menu {
        case .unpin, .removeFromRecents:
            titleLabel?.textColor = .appColor(.destructiveRed)
        default:
            titleLabel?.textColor = .label
        }
        
        titleLabel?.text = menu.localizedTitle
    }

}
