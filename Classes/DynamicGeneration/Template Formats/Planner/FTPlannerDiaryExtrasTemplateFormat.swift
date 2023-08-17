//
//  FTPlannerDiaryExtrasTemplateFormat.swift
//  Noteshelf
//
//  Created by Ramakrishna on 23/11/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTPlannerDiaryExtrasTemplateFormat  :FTPlannerDiaryTemplateFormat {
    override func renderTemplate(context: CGContext) {
        super.renderTemplate(context: context)
        self.renderiPadTemplate(context: context)
    }
    private func renderiPadTemplate(context : CGContext){
    }
}
