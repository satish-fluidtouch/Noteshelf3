//
//  NSMutableParagraphStyle+Extension.swift
//  Noteshelf
//
//  Created by Sameer on 14/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

extension NSMutableParagraphStyle {

    func increaseIndentation(withScale scale: CGFloat) {
          let headIndent = firstLineHeadIndent
          firstLineHeadIndent = headIndent + CGFloat((indentOffset * scale))
      }

    func decreaseIndentation(withScale scale: CGFloat) {
        let headIndent = firstLineHeadIndent
        if headIndent > 0.01 {
            firstLineHeadIndent = headIndent - CGFloat((indentOffset * scale))
            firstLineHeadIndent = (firstLineHeadIndent > 0.01) ? firstLineHeadIndent : 0.0
        }
    }

    func increaseBulletIndentation(withScale scale: CGFloat) {
        let headIndent = self.headIndent
        self.headIndent = headIndent + CGFloat((indentOffset * scale))

        let originalTabStops = NSParagraphStyle.default.tabStops
        var tabs: [NSTextTab] = []

        var index = 0
        for eachTab in originalTabStops {
            let tab = NSTextTab(textAlignment: eachTab.alignment, location: CGFloat(indentOffset * scale * CGFloat(Float(index))), options: eachTab.options)
            tabs.append(tab)
            index += 1
        }
        self.tabStops = tabs

        defaultTabInterval = CGFloat(2 * (indentOffset * scale))
    }

   func decreaseBulletIndentation(withScale scale: CGFloat) {
        let headIndent = self.headIndent
        if headIndent > 0.01 {
            self.headIndent = headIndent - CGFloat((indentOffset * scale))
            self.headIndent = (self.headIndent > 0.01) ? self.headIndent : 0.0
        } else {
            let style = NSParagraphStyle.default
            tabStops = style.tabStops
            defaultTabInterval = style.defaultTabInterval
        }
    }
    
   func resetBulletIndentations() {
     let defaultParagraphStyle = NSParagraphStyle.default
     self.bulletLists?.removeAll()
     self.headIndent = 0
     self.tabStops = defaultParagraphStyle.tabStops
     self.defaultTabInterval = defaultParagraphStyle.defaultTabInterval
   }
}
