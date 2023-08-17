//
//  FTTooltipModel.swift
//  Noteshelf
//
//  Created by Simhachalam on 01/02/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc enum FTTipDirection: Int{
    case top
    case left
    case bottom
    case right
}

class FTTooltipModel: NSObject {
    
    var tooltipID:String!
    var tooltipMessage:String!
    var canExpire:Bool = false
    var shouldTapToDismiss:Bool = false
    var textMaxWidth:Float! = 0
    var tipDirection: FTTipDirection = FTTipDirection.top
    
    init(withDictionary dictionary:[String : Any]) {
        super.init()
        self.tooltipID = (dictionary["ID"] as! String)
        self.tooltipMessage = NSLocalizedString(dictionary["ID"] as! String, comment: "")
        self.canExpire = dictionary["canExpire"] as! Bool
        self.shouldTapToDismiss = dictionary["shouldTapToDismiss"] as! Bool
        self.tipDirection = FTTipDirection(rawValue: (dictionary["tipDirection"] as! NSNumber).intValue)!
    }
}
