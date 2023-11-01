//
//  FTGestureHelpTableViewCell.swift
//  Noteshelf
//
//  Created by Sameer on 30/08/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import UIKit

class FTGestureHelpTableViewCell : UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!

    fileprivate var gestureOption: FTGestureHelpOptions?

    func configureGestureCell(with gesture: FTGestureHelpOptions) {
        self.title.text = gesture.localizedTitle
        self.subTitle.text = gesture.localizedSubTitle
        self.thumbnail.image = gesture.thumbnail
    }

}
