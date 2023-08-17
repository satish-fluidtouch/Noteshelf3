//
//  NSTextAttachment_Extension.swift
//  Noteshelf
//
//  Created by Amar on 27/09/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension NSTextAttachment {
  func updateFileWrapperIfNeeded()
    {
        if(nil == self.fileWrapper) {
            if let image = self.image,let imageData = image.pngData() {
                let fileWrapper = FileWrapper.init(regularFileWithContents: imageData);
                fileWrapper.preferredFilename = "Attachment.png";
                self.fileWrapper = fileWrapper;
            }
        }
    }
}
