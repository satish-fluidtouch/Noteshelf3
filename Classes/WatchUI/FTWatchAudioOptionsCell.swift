//
//  FTWatchAudioOptionsCell.swift
//  Noteshelf
//
//  Created by Simhachalam on 08/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTWatchAudioOptionsCell: UITableViewCell {

    @IBOutlet weak var titleLabel : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func applyActionStyle(_ style:FTAudioActionStyle){
        if(style == .regular){
            self.titleLabel.textColor = UIColor.appColor(.accent)
        }
        else if(style == .destructive){
            self.titleLabel.textColor = UIColor.appColor(.destructiveRed)
        }
    }
}
