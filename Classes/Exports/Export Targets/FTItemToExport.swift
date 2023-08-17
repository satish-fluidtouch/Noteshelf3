//
//  FTItemToExport.swift
//  Noteshelf
//
//  Created by Amar on 10/01/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import Foundation

class FTItemToExport: NSObject {
    var shelfItem : FTShelfItemProtocol!
    var destinationURL : URL?

    private var _filename : String?;
    var filename : String? {
        get {
            return _filename;
        }
        set {
            _filename = newValue
            if(nil != newValue) {
                _filename = (newValue! as NSString).validateFileName();
            }
        }
    }
        
    convenience init(shelfItem : FTShelfItemProtocol) {
        self.init();
        self.shelfItem = shelfItem
        self.filename = shelfItem.displayTitle
    }
    
    var preferedFileName : String
    {
        var preferedName = NSLocalizedString("Untitled", comment: "Untitled");
        if let filename = self.filename, filename != ""
        {
            preferedName = filename;
        }
        return preferedName;
    }

}
