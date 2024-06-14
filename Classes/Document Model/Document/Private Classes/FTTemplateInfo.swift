//
//  FTTemplateInfo.swift
//  Noteshelf
//
//  Created by Amar on 17/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

private typealias FTTemplateInfoKey = String;
private extension FTTemplateInfoKey {
    static let version = "version";
    static let isTemplate = "isTemplate";
    static let isImageTemplate = "sourcedFromImage";
    static let renderAnnotations = "renderAnnotations";
    static let footerOption = "footerOption";
    static let password = "password";
    static let isCover = "isCover";
    static let isReadOnly = "isReadOnly"
}

@objcMembers class FTTemplateInfo: NSObject {
    var version: String = DOC_VERSION;

    var isTemplate: Bool = true;
    var isImageTemplate: Bool = false;
    var renderAnnotations: Bool = true;
    var isCover: Bool = false

    var footerOption: FTPageFooterOption = FTPageFooterOption.show;

    private var encryptedPassword: String?
    
    var password: String? {
        get {
            var passwordToReturn:String?;
            if let valueToRead = encryptedPassword {
                passwordToReturn = FTUtils.decryptString(valueToRead,
                                                         allowDefaultValue: false,
                                                         privateKey: nil);
            }
            return passwordToReturn;
        }
        set {
            if let valueToSet = newValue {
                encryptedPassword = FTUtils.encryptString(valueToSet,
                                                        allowDefaultValue: false,
                                                        privateKey: nil);
            }
            else {
                encryptedPassword = nil;
            }
        }
    };
    
    convenience init(documentInfo info: FTDocumentInputInfo) {
        self.init();
        self.isImageTemplate = info.isImageSource;
        self.isTemplate = info.isTemplate;
        self.footerOption = info.footerOption;
        self.isCover = info.isCover
    }
    
    convenience init(info : [String: AnyObject])
    {
        self.init();
        self.version = (info[FTTemplateInfoKey.version] as? String) ?? DOC_VERSION;

        self.isTemplate = (info[FTTemplateInfoKey.isTemplate] as? NSNumber)?.boolValue ?? false;
        self.isImageTemplate = (info[FTTemplateInfoKey.isImageTemplate] as? NSNumber)?.boolValue ?? false;
        self.isCover = (info[FTTemplateInfoKey.isCover] as? NSNumber)?.boolValue ?? false;
        self.renderAnnotations = (info[FTTemplateInfoKey.renderAnnotations] as? NSNumber)?.boolValue ?? false;
        
        if let footerValue = info[FTTemplateInfoKey.footerOption] as? NSNumber {
            self.footerOption = FTPageFooterOption(rawValue: footerValue.intValue) ?? .show;
        }
        else {
            self.footerOption = self.isTemplate ? .show : .hide;
        }

        if let _password = info[FTTemplateInfoKey.password] as? String {
            self.encryptedPassword = _password;
        }
    }
    
    func dictRepresenataion() -> [String: AnyObject] {
        var dictRep = [String: AnyObject]();
        dictRep[FTTemplateInfoKey.version] = self.version as AnyObject;
        
        dictRep[FTTemplateInfoKey.isTemplate] = NSNumber(value: self.isTemplate);
        dictRep[FTTemplateInfoKey.isCover] = NSNumber(value: self.isCover);
        if(self.isImageTemplate) {
            dictRep[FTTemplateInfoKey.isImageTemplate] = NSNumber(value: self.isImageTemplate);
        }
        if(self.renderAnnotations) {
            dictRep[FTTemplateInfoKey.renderAnnotations] = NSNumber(value: self.renderAnnotations);
        }

        dictRep[FTTemplateInfoKey.footerOption] = NSNumber(value: self.footerOption.rawValue);
        
        if let _password = self.encryptedPassword {
            dictRep[FTTemplateInfoKey.password] = _password as AnyObject;
        }
        
        return dictRep;
    }
}

extension FTTemplateInfo: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = FTTemplateInfo();
        copy.version = self.version;
        
        copy.isTemplate = self.isTemplate;
        copy.isCover = self.isCover;
        copy.isImageTemplate = self.isImageTemplate;
        copy.renderAnnotations = self.renderAnnotations;
        
        copy.footerOption = self.footerOption;
        copy.encryptedPassword = self.encryptedPassword;
        
        return copy
    }
}
