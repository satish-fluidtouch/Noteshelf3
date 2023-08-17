//
//  FTMediaFilterCell.swift
//  Noteshelf3
//
//  Created by Sameer on 02/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit
import FTCommon

class FTMediaFilterCell: UITableViewCell {
    @IBOutlet var checkMarkImage: UIImageView?
    @IBOutlet var titleLabel: FTCustomLabel?
    @IBOutlet var accessoryImage: UIImageView?
    
    func configureCell(with media: FTMediaProtocol) {
        titleLabel?.text = media.name
        accessoryImage?.image = UIImage(systemName: media.imageName)
    }
    
    override var isSelected: Bool {
        didSet {
            checkMarkImage?.isHidden = !isSelected
        }
    }
}
