//
//  File.swift
//  
//
//  Created by Narayana on 10/06/22.
//

import UIKit
import FTCommon
import CoreServices

let noteshelfDocumentsExt = "nsdata"

extension FTFileImporter {
    func convertFileToPDF(filePath: String,
                          onCompletion:@escaping ((_ filePath: String?,
                                                   _ error: NSError?,
                                                   _ isImageSource: Bool) -> Void)) -> Progress {
        let progress = Progress()
        progress.totalUnitCount = 1

        var mimeType: NSString?
        let shouldConvert = shouldConvertToPDF(filePath, &mimeType)

        guard mimeType != nil else {
            onCompletion(nil, NSError.importFailError, false)
            return progress
        }

        if let window = UIApplication.shared.keyWindow, shouldConvert {
            FTPDFConverter.shared.convertToPDF(filePath: filePath, view: window, onSuccess: { path in
                _ = try? FileManager.default.removeItem(atPath: filePath)
                progress.completedUnitCount += 1
                onCompletion(path, nil, false)
            }, onFailure: { error in
                _ = try? FileManager.default.removeItem(atPath: filePath)
                progress.completedUnitCount += 1
                onCompletion(nil, error as NSError?, false)
            }, progress: nil)
        } else {
            progress.completedUnitCount += 1
            onCompletion(filePath, nil, false)
        }
        return progress
    }
}
