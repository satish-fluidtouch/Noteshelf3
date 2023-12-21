//
//  FTDocumentPostProcessInfo.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 20/12/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

enum FTPostProcessType
{
    case none,diary;
}

class FTDocumentPostProcessInfo : FTPostProcessInfo {
    var templateURL : URL!
    var pagesInfo : [Int : FTDocumentPageInfo]!
    var postProcessType = FTPostProcessType.diary;

    @objc convenience init (docFileURL : URL, pagesInfo : [Int : FTDocumentPageInfo]){
        self.init()
        self.templateURL = docFileURL
        self.pagesInfo = pagesInfo
    }
}
