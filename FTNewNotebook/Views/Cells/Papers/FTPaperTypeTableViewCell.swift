//
//  FTPaperTypeTableViewCell.swift
//  FTNewNotebook
//
//  Created by Rakesh on 19/05/23.
//

import UIKit

class FTPaperTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var deviceSizeBtn: UIButton!
    @IBOutlet weak var paperSizeLable: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
