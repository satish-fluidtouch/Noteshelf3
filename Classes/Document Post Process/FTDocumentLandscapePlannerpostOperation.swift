//
//  FTDocumentLandscapePlannerpostOperation.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTDocumentLandscapePlannerpostOperation :NSObject, FTPostProcess {

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
                if let docPostProcessInfo = (self.documentInfo.postProcessInfo as? FTDocumentPostProcessInfo), let pagesInfo = docPostProcessInfo.pagesInfo{
                    for page in doc.pages(){
                        if let noteShelfPage = page as? FTNoteshelfPage, let pageInfo =  pagesInfo.first(where: {$0.key == noteShelfPage.pageIndex()})?.value{

                            if let pageDate = pageInfo.currentDate {
                                noteShelfPage.pageDate = pageDate
                            }
                        }
                    }
                }
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
            return postProcessInfo.offsetCount + numberOfDays + 1  // as we are inserting cover in the starting of notebook so explicitly adding 1
        }

        return 0
    }
}
