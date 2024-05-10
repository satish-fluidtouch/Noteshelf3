//
//  FTCustomizeToolbarCell.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 12/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCustomizeToolbarCell: UITableViewCell {
    
    @IBOutlet weak private(set) var titleLbl: UILabel!
    @IBOutlet weak private(set) var iconImg: UIImageView!
    @IBOutlet weak var newLbl: UILabel!
    @IBOutlet weak private(set) var newBgView: UIView!
    @IBOutlet weak private(set) var newViewWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setNewBgWidth(value : Double){
        let width = value * Double(10.5)
        if width == 11 {
            newViewWidth.constant = 28
            return
        }
        if width < 40 {
            newViewWidth.constant = 40
        }else {
            newViewWidth.constant = CGFloat(width)
        }
        
    }

}
