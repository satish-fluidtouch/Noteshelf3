//
//  FTDocumentDigitalDiaryPostOperation.swift
//  Noteshelf
//
//  Created by sreenu cheedella on 16/01/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class FTDocumentDigitalDiaryPostOperation: NSObject, FTPostProcess {
    fileprivate var fileURL : URL!
    fileprivate var documentInfo : FTDocumentInputInfo!
    
    required init(url: URL, info: FTDocumentInputInfo) {
        super.init()
        self.fileURL = url
        self.documentInfo = info
    }
    
    func perform(completion: @escaping () -> Void) {
        let pageNumber = pageNumberForCurrentDate(currentDate: Date())
        
        let openRequest = FTDocumentOpenRequest(url: self.fileURL, purpose: .write);
        FTNoteshelfDocumentManager.shared.openDocument(request: openRequest) { (token, document, _) in
            if let doc = document {
                doc.localMetadataCache?.lastViewedPageIndex = pageNumber;
                FTNoteshelfDocumentManager.shared.saveAndClose(document: doc, token: token) { (_) in
                    completion()
                }
            }
            else {
                completion()
            }
        }
    }
    
    func pageNumberForCurrentDate(currentDate: Date) -> Int {
        let postProcessInfo = documentInfo.postProcessInfo
        let startDate = postProcessInfo.startDate!
        let endDate = postProcessInfo.endDate!
        if (currentDate.compare(startDate) == ComparisonResult.orderedSame ||
            currentDate.compare(startDate) == ComparisonResult.orderedDescending)
            && (currentDate.compare(endDate) == ComparisonResult.orderedSame ||
                currentDate.compare(endDate) == ComparisonResult.orderedAscending) {
            return postProcessInfo.offsetCount + startDate.daysBetween(date: currentDate)
        }
        
        return 0
    }
}
