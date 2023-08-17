//
//  FTTextAnnotationBackgroundCell.swift
//  Noteshelf
//
//  Created by Mahesh on 07/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTTextAnnotationBackgroundCell: UITableViewCell {

    @IBOutlet private weak var colorImg: UIImageView?
    @IBOutlet private weak var colorLbl: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.accessoryType = isSelected ? .checkmark : .none
    }
    
    func updateCell(_ item: FTTextBackgroundProtocol) {
        self.colorImg?.image = item.image
        self.colorLbl?.text = item.name
    }

}
