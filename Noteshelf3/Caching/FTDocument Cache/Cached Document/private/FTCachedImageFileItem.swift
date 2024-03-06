//
//  FTCachedImageFileItem.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 06/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTCachedImageFileItem: FTFileItemImage {
    private var _image: UIImage?;
    private let maxImageSize = CGSize(width: 500, height: 500);

    override func image() -> UIImage! {
        fatalError("Call image(onCompletion:)");
    }
    
    func image(onCompletion: ((UIImage?)->())?) {
        guard nil == _image else {
            onCompletion?(self._image)
            return;
        }
        let cooridinator = NSFileCoordinator();
        var error: NSError?
        cooridinator.coordinate(readingItemAt: self.fileItemURL, writingItemAt: self.fileItemURL, error: &error) { readingURL, writingURL in
            let imagePath = readingURL.path(percentEncoded: false);
            guard let resourceImage = UIImage(contentsOfFile: imagePath) else {
                onCompletion?(nil);
                return;
            }
            if resourceImage.size.width > self.maxImageSize.width || resourceImage.size.height > self.maxImageSize.height
            , let imageToReturn = resourceImage.preparingThumbnail(of: self.maxImageSize) {
                self._image = imageToReturn;
                let modifiedTime = writingURL.fileModificationDate;
                if let data = imageToReturn.pngData() {
                    do {
                        try data.write(to: writingURL, options: .atomic)
                        try FileManager().setAttributes([.modificationDate:modifiedTime], ofItemAtPath: imagePath);
                        debugLog("image updated: \(readingURL.lastPathComponent)");
                    }
                    catch {
                        debugLog("error: \(error)");
                    }
                }
                onCompletion?(self._image);
            }
            else {
                self._image = resourceImage;
                onCompletion?(self._image);
            }
        }
    }
    
    override func saveContentsOfFileItem() -> Bool {
        fatalError("No saving of cache fileItem")
    }
}
