//
//  FTFontStyles.swift
//  Noteshelf
//
//  Created by Amar on 22/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTFontStyles: NSObject {
    
    var headerStyle1Font : UIFont {
        return UIFont.init(name: "HelveticaNeue-Bold", size: CGFloat(28))!;
    }
    
    var headerStyle2Font : UIFont {
        return UIFont.init(name: "HelveticaNeue-Bold", size: CGFloat(24))!;
    }
    
    var headerStyle3Font : UIFont {
        return UIFont.init(name: "HelveticaNeue-Bold", size: CGFloat(20))!;
    }
    
    @objc var bodyFont : UIFont {
        
        return UIFont.init(name: "HelveticaNeue", size: CGFloat(20))!;
    }
}
