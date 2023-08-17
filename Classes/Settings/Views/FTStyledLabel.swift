//
//  FTStyledLabel.swift
//  Noteshelf
//
//  Created by Siva on 2/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objc enum FTLabelStyle: Int {
    case defaultStyle = 0   //case body = 0 point16
    case style1             //case bodyCaption = 1 point9
    case style2             //case caption = 2 point11
    case style3             //case footer = 3 point12
    case style4             //case shelfTitle = 4 point13
    case style5             //case bodySubTitle = 5 point14
    case style6             //case header = 6 point19
    case style7             //case helpMessage = 7 point15
    case style8             //case point22 = 8
    case style9             //case point18 = 9
    case style10            //case point17 = 10
    case style11            //case point32
    case style12
    case style13
    case style14
    case style15
    case style16
    case style17
    case style18
    case style19
    case style20            //bold point 22
    case style21            //Regular point 22
    case style22            //Regular point 24
    case style23            //Bold point 24
    case style24            //Medium point 16
    case style25
    case style26            //Display Bold point 48
    case style27            //Display Regular point 19
    case style28            //Display Bold point 40
    case style29            //Display Bold point 70
    case style30            //Display Bold point 70
}

@objcMembers class FTStyledLabel: UILabel {
    @IBInspectable var localizationKey: String?
    @IBInspectable var localizationTable: String?    
    @IBInspectable var style: Int = 0;
    
    var kernValue: Double = defaultKernValue
    
    fileprivate func styleFont() -> UIFont {
        let labelStyle = FTLabelStyle(rawValue: self.style);
        var font: UIFont!;
        switch labelStyle! {
        case .defaultStyle: //0
            font = UIFont.appFont(for: .regular, with: 16)
        case .style1: //1
            font = UIFont.appFont(for: .regular, with: 9)
        case .style2: //2
            font = UIFont.appFont(for: .regular, with: 11)
        case .style3: //3
            font = UIFont.appFont(for: .regular, with: 12)
        case .style4: //4
            font = UIFont.appFont(for: .regular, with: 13)
        case .style5: //5
            font = UIFont.appFont(for: .regular, with: 14)
        case .style6: //6
            font = UIFont.appFont(for: .regular, with: 19)
        case .style7: //7
            font = UIFont.appFont(for: .regular, with: 15)
        case .style8: //8
            font = UIFont.appFont(for: .regular, with: 22)
        case .style9: //9
            font = UIFont.appFont(for: .regular, with: 18)
        case .style10: //10
            font = UIFont.appFont(for: .regular, with: 17)
        case .style11: //11
            font = UIFont.appFont(for: .regular, with: 32)
        case .style12: //12 montserrat-extra bold
            font = UIFont.montserratFont(for: .extraBold, with: 40)
        case .style13: //13 montserrat-extra bold
            font = UIFont.montserratFont(for: .light, with: 18)
        case .style14: //14
            font = UIFont.appFont(for: .bold, with: 17)
        case .style15: //15
            font = UIFont.appFont(for: .regular, with: 10)
        case .style16: //16 montserrat-semi bold 20
            font = UIFont.montserratFont(for: .semibold, with: 20);
        case .style17: //17 montserrat-semi bold 11.5
            font = UIFont.montserratFont(for: .semibold, with: 11.5)
        case .style18: //18 montserrat-extra bold
            font = UIFont.montserratFont(for: .extraBold, with: 32)
        case .style19: //19 montserrat-extra bold
            font = UIFont.montserratFont(for: .extraBold, with: 70)
        case .style20: //20
            font = UIFont.appFont(for: .bold, with: 22)
        case .style21: //21
            font = UIFont.appFont(for: .regular, with: 20)
        case .style22: //22
            font = UIFont.appFont(for: .regular, with: 24)
        case .style23: //23
            font = UIFont.appFont(for: .bold, with: 24)
        case .style24: //24
            font = UIFont.appFont(for: .medium, with: 16)
        case .style25: //25
            font = UIFont.appFont(for: .semibold, with: 19)
        case .style29: //28 Using only for whats new first slide
            font = UIFont.montserratFont(for: .extraBold, with: 70)
        case .style30: //28 Using only for whats new first slide
            font = UIFont.montserratFont(for: .extraBold, with: 70)
        default:
            font = UIFont.systemFont(ofSize: 20, weight: .regular)
        }
        return font;
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let localizationKey = self.localizationKey {
            var title = NSLocalizedString(localizationKey, comment: self.text ?? "");
            if let table = self.localizationTable,!table.isEmpty {
                title =  NSLocalizedString(localizationKey,
                                           tableName: table,
                                           bundle: Bundle.main,
                                           value: "",
                                           comment:self.text ?? "")
            }
            self.text = title;
        }
    }

     var styleText: String? {
        didSet {
            let title = self.styleText;
            if(nil != title) {
                let attrTitle = NSAttributedString(string: title!, attributes: [NSAttributedString.Key.font: self.styleFont(), NSAttributedString.Key.foregroundColor: self.textColor!, NSAttributedString.Key.kern: NSNumber(value: kernValue)]);
                self.attributedText = attrTitle;
            } else {
                self.attributedText = nil;
            }
        }
    }

    var styledAttributedText: NSAttributedString? {
        didSet {
            if let styledAttributedText = self.styledAttributedText {
                let attrTitle = NSMutableAttributedString(attributedString: styledAttributedText);
                attrTitle.addAttributes([NSAttributedString.Key.kern: NSNumber(value: defaultKernValue)], range: NSRange(location: 0, length: styledAttributedText.length));
                self.attributedText = attrTitle;
            } else {
                self.attributedText = nil;
            }
        }
    }

    var styledAttributedTextForWhatsNewHelpMessage: NSAttributedString? {
        didSet {
            if let styledAttributedText = self.styledAttributedTextForWhatsNewHelpMessage {
                let attrTitle = NSMutableAttributedString(attributedString: styledAttributedText);
                attrTitle.addAttributes([NSAttributedString.Key.font: self.styleFont(), NSAttributedString.Key.foregroundColor: self.textColor!, NSAttributedString.Key.kern: NSNumber(value: -0.4)], range: NSRange(location: 0, length: styledAttributedText.length));
                self.attributedText = attrTitle;
            } else {
                self.attributedText = nil;
            }
        }
    }

    var styledAttributedTextForWhatsNewHelpTitle2: String? {
        didSet {
            let title = self.styledAttributedTextForWhatsNewHelpTitle2;
            if(nil != title) {
                let attrTitle = NSAttributedString(string: title!, attributes: [NSAttributedString.Key.font: self.styleFont(), NSAttributedString.Key.foregroundColor: self.textColor!, NSAttributedString.Key.kern: NSNumber(value: 1)]);
                self.attributedText = attrTitle;
            } else {
                self.attributedText = nil;
            }
        }
    }
}
