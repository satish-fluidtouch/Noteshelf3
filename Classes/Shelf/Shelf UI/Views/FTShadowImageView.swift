//
//  FTShadowImageView.swift
//  Noteshelf
//
//  Created by Siva on 20/06/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTShadowImageView: UIImageView {
    override func awakeFromNib() {
        self.image = self.image?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 3, left: 10, bottom: 3, right: 10), resizingMode: UIImage.ResizingMode.stretch);
    }
}

class FTSelectionBorderImageView: UIImageView {
    override func awakeFromNib() {
        self.image = self.image?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 20, left: 20, bottom: 20, right: 20), resizingMode: UIImage.ResizingMode.stretch);
    }
}

class FTShelfItemShadowImageView: UIImageView {
    override func awakeFromNib() {
        self.image = self.image?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10), resizingMode: UIImage.ResizingMode.stretch);
    }
}
