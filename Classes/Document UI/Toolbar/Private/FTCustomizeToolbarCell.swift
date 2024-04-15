//
//  FTCustomizeToolbarCell.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 12/04/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCustomizeToolbarCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var iconImg: UIImageView!
    @IBOutlet weak var newLbl: UILabel!
    @IBOutlet weak var newBgView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setUpUi(){
        newBgView.layer.cornerRadius = 6
    }

}
