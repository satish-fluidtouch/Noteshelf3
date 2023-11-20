//
//  NSTextAttachment_Extension.swift
//  Noteshelf
//
//  Created by Amar on 27/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension NSTextAttachment {
    func updateFileWrapperIfNeeded(migrate: Bool = false)
    {
        if(nil == self.fileWrapper) {
            if let image = self.image, let imageData = image.pngData() {
                let fileWrapper = FileWrapper.init(regularFileWithContents: imageData);
                fileWrapper.preferredFilename = "Attachment.png";
                self.fileWrapper = fileWrapper;
            }
        } else {
            if migrate {
                let contents = self.fileWrapper?.regularFileContents
                let ns2CheckBoxOffAttachmentData = UIImage(named: "check-off-2x_ns2.png")?.pngData()
                let ns2CheckBoxonAttachmentData = UIImage(named: "check-on-2x_ns2.png")?.pngData()
                guard let checkBoxOffContents = ns2CheckBoxOffAttachmentData,
                    let checkBoxOnContents = ns2CheckBoxonAttachmentData
                    else {
                        return;
                }
                let isSameAsCheckOff = (contents == checkBoxOffContents);
                let isSameAsCheckOn = (contents == checkBoxOnContents);

                if isSameAsCheckOff || isSameAsCheckOn {
                    let image = isSameAsCheckOff ? UIImage(named: "check-off-2x.png") : UIImage(named: "check-on-2x.png")
                    if let image, let imageData = image.pngData() {
                        let fileWrapper = FileWrapper.init(regularFileWithContents: imageData);
                        fileWrapper.preferredFilename = "Attachment.png";
                        self.fileWrapper = fileWrapper;
                    }
                }
            }
        }
    }
}
