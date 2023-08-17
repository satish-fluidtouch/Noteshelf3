//
//  FTDocumentColorfulPlannerpostOperation.swift
//  Noteshelf
//
//  Created by Ramakrishna on 07/12/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTDocumentPlannerpostOperation :NSObject, FTPostProcess {
    
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
            let numberOfDays = startDate.daysBetween(date: currentDate)
            return postProcessInfo.offsetCount + numberOfDays
        }
        
        return 0
    }
}
