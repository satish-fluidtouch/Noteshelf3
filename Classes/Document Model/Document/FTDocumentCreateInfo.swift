//
//  FTDocumentCreateInfo.swift
//  Noteshelf
//
//  Created by Amar on 18/7/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

@objc enum FTPageFooterOption : Int {
    case show = 0
    case hide
}

class FTPageProperties:NSObject {
    var lineHeight: Int = Int(34);
    var bottomMargin: Int = 0;
    var topMargin: Int = 0;
    var leftMargin: Int = 0;
}

class FTDocumentInputInfo: NSObject {
    var inputFileURL : URL?;
    var isTemplate : Bool  = false;
    var isCustomTemplate : Bool  = false;
    var footerOption : FTPageFooterOption  = .hide;

    var insertAt : Int = 0;
    var isImageSource : Bool = false;
    var isNewBook : Bool  = false;

    var pageProperties = FTPageProperties();

    var coverTemplateImage : UIImage?;
    var coverTemplateUrl:  URL?;
    var backgroundColor : UIColor?;
    var isCover = false
    #if  !NS2_SIRI_APP && !NOTESHELF_ACTION
    var overlayStyle : FTCoverStyle = FTCoverStyle.clearWhite;
    
    #endif
    var pinModel : FTDocumentPin?;
    var annotationInfo : [String : Any]?;
    
    weak var rootViewController : UIViewController?;
    var diaryPagesInfo: [FTDiaryPageInfo]?;
    var isEnCrypted: Bool {
        if let pin = self.pinModel?.pin, !pin.isEmpty {
            return true
        }
        return false
    }
}
