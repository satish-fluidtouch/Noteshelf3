//
//  FTCheckBoxTextList.swift
//  Noteshelf
//
//  Created by Sameer on 14/09/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
class FTCheckBoxTextList: FTTextList {
    
    override func marker(forItemNumber itemNum: Int) -> String {
        return "{checkbox}"
    }

    override func attributedMarker(forItemNumber itemNumber: Int, scale: CGFloat) -> NSAttributedString? {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "check-off-2x.png")
        attachment.updateFileWrapperIfNeeded()
        var attachmentBounds = attachment.bounds
        attachmentBounds.size = CGSize(width: CHECKBOX_WIDTH, height: CHECKBOX_HEIGHT)
        attachmentBounds.origin.y = CGFloat(CHECK_BOX_OFFSET_Y)
        attachment.bounds = CGRectScale(attachmentBounds, scale)

        let attributedSting = NSAttributedString(attachment: attachment)
        return attributedSting
    }
    
    //In iOS17 NSTextList is expecting a below Selector to layout the string, since it is a internal method we are not sure what is signature of it. Hence returing default attachment for checkbox.
    override func markerTextAttachment() -> NSTextAttachment? {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "check-off-2x.png")
        var attachmentBounds = attachment.bounds
        attachmentBounds.size = CGSize(width: CHECKBOX_WIDTH, height: CHECKBOX_HEIGHT)
        attachmentBounds.origin.y = CGFloat(CHECK_BOX_OFFSET_Y)
        attachment.bounds = attachmentBounds
        return attachment
    }
}
