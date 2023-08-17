//
//  FTFiveMinJournalMonthTemplate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 12/07/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTFiveMinJournalMonthTemplate : FTFiveMinJournalTemplateFormat {
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
            self.renderiPhoneTemplate(context: context)
    }
    private func renderiPhoneTemplate(context : CGContext){
        let isLandscape = templateInfo.customVariants.isLandscape
        let bottomBGColorX : CGFloat = isLandscape ? 57.87 : 0.0
        let bottomBGColorY : CGFloat =  isLandscape ? 0.0 : 49.72
        let bottomBGHeight : CGFloat =  isLandscape ? 100 : 50.27
        let bottomBGWidth : CGFloat =  isLandscape ? 43.77 : 100
        
        //bottomBG color rendering
        
        let bottomBGColorYValue = templateInfo.screenSize.height*CGFloat(bottomBGColorY)/100
        let bottomBGColorHeightValue = templateInfo.screenSize.height*CGFloat(bottomBGHeight)/100
        let bottomBGColorXValue = templateInfo.screenSize.width*CGFloat(bottomBGColorX)/100
        let bottomBGColorWidthValue = templateInfo.screenSize.width*CGFloat(bottomBGWidth)/100
        
        let bgRect = CGRect(x: bottomBGColorXValue, y: bottomBGColorYValue, width: bottomBGColorWidthValue, height: bottomBGColorHeightValue)
        context.setFillColor(UIColor(hexString: "#E1E9E8", alpha: 1.0).cgColor)
        context.fill(bgRect)
    }
}
