//
//  FTFileImporter.swift
//  Noteshelf
//
//  Created by Amar on 10/3/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

class FTFileImporter: NSObject {
    @discardableResult func pdfFileFrom(_ item: FTImportItem,
                     onCompletion : @escaping ((_ filePath: String?, _ error: NSError?, _ isImageSource: Bool) -> Void)) -> Progress
    {
        let progress = Progress();
        progress.totalUnitCount = 1;
        
        if let image = item.importItem as? UIImage {
            FTPDFFileGenerator().generatePDFFile(withImages: [image], onCompletion: {(filePath) in
                progress.completedUnitCount += 1;
                track("convert_document", params: ["type": "image"])
                onCompletion(filePath, nil, true);
            })
        } else if let string = item.importItem as? String {
            let subProgress = self.convertFileToPDF(string, onCompletion: onCompletion);
            progress.addChild(subProgress, withPendingUnitCount: 1);
        } else if let url = item.importItem as? URL {
            let filePath = url.path;
            let subProgress = self.convertFileToPDF(filePath, onCompletion: onCompletion);
            progress.addChild(subProgress, withPendingUnitCount: 1);
        }
        else {
            fatalError("should not reach here:\(item)");
        }
        return progress;
    }

    fileprivate func convertFileToPDF(_ filePath: String,
                                      onCompletion:@escaping ((_ filePath: String?, _ error: NSError?, _ isImageSource: Bool) -> Void)) -> Progress {
        let progress = Progress();
        progress.totalUnitCount = 1;
        
        var mimeType: NSString?;
        let shouldConvert = shouldConvertToPDF(filePath, &mimeType);
        
        guard nil != mimeType else {
            onCompletion(nil, NSError.importFailError, false);
            return progress
        }
        
    #if targetEnvironment(macCatalyst)
        progress.completedUnitCount += 1;
        onCompletion(filePath, nil, false);
    #else
        if let window = UIApplication.shared.keyWindow , shouldConvert {
            track("convert_document", params: ["type": (filePath as NSString).pathExtension.lowercased()])
            FTPDFConverter.shared.convertToPDF(filePath: filePath, view: window,onSuccess: { path in
                _ = try? FileManager.default.removeItem(atPath: filePath);
                progress.completedUnitCount += 1;
                onCompletion(path, nil, false);
            }, onFailure: { error in
                _ = try? FileManager.default.removeItem(atPath: filePath);
                progress.completedUnitCount += 1;
                onCompletion(nil, error as NSError?, false);
            }, progress: nil);
        } else {
            progress.completedUnitCount += 1;
            onCompletion(filePath, nil, false);
        }
    #endif
        return progress;
    }
}
