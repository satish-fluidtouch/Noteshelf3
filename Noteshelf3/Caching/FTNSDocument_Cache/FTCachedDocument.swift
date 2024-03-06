//
//  FTCachedDocument.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 05/03/24.
//  Copyright © 2024 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTDocumentFramework

class FTCachedDocument: FTDocument {
    override func fileItemFactory() -> FTFileItemFactory! {
        return FTNSCacheDocumentFactory();
    }
}

class FTNSCacheDocumentFactory: FTFileItemFactory {
    override func imageFileItem(with url: URL!) -> FTFileItem! {
        return FTCachedImageFileItem(url: url, isDirectory: false);
    }
    
    override func fileItem(with url: URL!, canLoadSubdirectory: Bool) -> FTFileItem! {
        if url.deletingLastPathComponent().lastPathComponent == FTNSqliteAnnotationFileItem.NON_STROKE_ANNOTATION_CACHE {
            return FTNonStrokeAnnotationFileItem(url: url, isDirectory: false);
        }
        return super.fileItem(with: url, canLoadSubdirectory: false);
    }
}

class FTNonStrokeAnnotationFileItem: FTFileItemPlist {
    
}

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
            if resourceImage.size.width > self.maxImageSize.width || resourceImage.size.height > self.maxImageSize.height {
                var imageToReturn = resourceImage.preparingThumbnail(of: self.maxImageSize);
                self._image = resourceImage;
                let modifiedTime = writingURL.fileModificationDate;
                if let data = imageToReturn?.pngData() {
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
}
