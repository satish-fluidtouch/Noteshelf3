//
//  FTNoteshelfAI_String_Extension.swift
//  Noteshelf3
//
//  Created by Amar Udupa on 04/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

extension String {
    func openAITrim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
    }
    
    var openAIDisplayString: String {
        let trimmedString = self.openAITrim().components(separatedBy: .newlines).joined(separator: " ").trimmedToLength(19)
        return trimmedString;
    }

    func trimmedToLength(_ length: Int) -> String {
        if self.count > length {
            let index = self.index(self.startIndex, offsetBy: length)
            let substring = self.prefix(upTo: index) // Hello
            return String(substring.appending("..."));
        }
        return self;
    }
    
    var aiLocalizedString: String {
        return NSLocalizedString(self
                                 , tableName: "FTNoteshelfAILocalized"
                                 , bundle: Bundle(for: FTNoteshelfAIViewController.self)
                                 , value: self
                                 , comment: self);
    }
    
    var aiCommandString: String {
        return NSLocalizedString(self
                                 , tableName: "AICommands"
                                 , bundle: Bundle(for: FTNoteshelfAIViewController.self)
                                 , value: self
                                 , comment: self);
    }

    func appendBetalogo(font: UIFont) -> NSAttributedString {
        if let betabadge = UIImage(named: "beta badge") {
            return self.appendlogo(logo: betabadge, font: font);
        }
        let attrString = NSMutableAttributedString(string:self,attributes: [.font : font]);
        return attrString;
    }
    
    
    func appendlogo(logo : UIImage, font: UIFont,capTo: CGSize? = nil) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string:self);
        
        attrString.append(NSAttributedString(string: " "));
        let attachmentImage = NSTextAttachment(image: logo);
        
        var imgSize = logo.size;
        if let capToSzie = capTo {
            let aspectRatio = aspectFittedRatio(logo.size, capToSzie);
            imgSize = CGSizeScale(logo.size, aspectRatio);
        }
        
        let yOffset = (font.capHeight - imgSize.height) * 0.5;
        attachmentImage.bounds = CGRect(origin: CGPoint(x: 0, y: yOffset), size: imgSize);
        
        let betaLogo = NSAttributedString(attachment: attachmentImage);
        attrString.append(betaLogo)

        attrString.addAttribute(.font, value: font, range: NSRange(location: 0, length: attrString.length));
        return attrString;
    }

}
