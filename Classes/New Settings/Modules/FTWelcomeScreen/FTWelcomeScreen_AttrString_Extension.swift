//
//  FTWelcomeScreen_AttrString_Extension.swift
//  Noteshelf
//
//  Created by Amar on 19/02/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension NSAttributedString {
    func add(foregroundColor : UIColor) -> NSAttributedString {
        let attr = NSMutableAttributedString.init(attributedString: self);
        attr.addAttribute(.foregroundColor, value: foregroundColor, range: NSRange.init(location: 0, length: self.length));
        return attr;
    }
}
