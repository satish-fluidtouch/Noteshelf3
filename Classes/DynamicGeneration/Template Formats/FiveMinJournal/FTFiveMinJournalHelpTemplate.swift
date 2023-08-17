//
//  FTFiveMinJournalHelpFormate.swift
//  Noteshelf
//
//  Created by Ramakrishna on 05/08/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import PDFKit

class FTFiveMinJournalHelpTemplate : FTFiveMinJournalTemplateFormat {
    
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        if templateInfo.customVariants.selectedDevice.isiPad {
            self.renderiPadTemplate(context: context)
        }
        else {
            self.renderiPhoneTemplate(context: context)
        }
    }
    private func renderiPhoneTemplate(context : CGContext){
        let bottomBGHeight = templateInfo.customVariants.isLandscape ? 27.79 : 20.02
        
        //bottomBG color rendering
        let bottomBGHeightValue = templateInfo.screenSize.height*CGFloat(bottomBGHeight)/100
        
        let bgRect = CGRect(x: 0, y: 0, width: templateInfo.screenSize.width, height: bottomBGHeightValue)
        context.setFillColor(self.bezierBoxesBGColor.cgColor)
        context.fill(bgRect)
    }
    private func renderiPadTemplate(context : CGContext){
        
        let bottomBGHeight = templateInfo.customVariants.isLandscape ? 31.16 : 28.53
        
        //bottomBG color rendering
        let bottomBGHeightValue = templateInfo.screenSize.height*CGFloat(bottomBGHeight)/100
        
        let bgRect = CGRect(x: 0, y: 0, width: templateInfo.screenSize.width, height: bottomBGHeightValue)
        context.setFillColor(self.bezierBoxesBGColor.cgColor)
        context.fill(bgRect)
    }
}
