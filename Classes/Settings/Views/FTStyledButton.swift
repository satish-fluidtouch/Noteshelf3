//
//  FTStyledButton.swift
//  Noteshelf
//
//  Created by Siva on 9/12/16.
//  Copyright © 2016 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objc enum FTButtonStyle : Int
{
    case defaultStyle       //case point16
    case style1             //case point15
    case style2             //case point17
    case style3             //case point11
    case style4             //case point19
    case style5             //case point14
    case style6             //case point12
    case style7             //case point22
    case style8             //case point13
    case style9             //case point16-Bold
    case style10             //case point14-Bold
    case style11             //case point14
    case style12             //case point22-montserrat-extralight
    case style13             //case point15-medium
    case style14             //case point19-medium
    case style15             //case point19-semibold
    case style16             //case point17-semibold
}

class FTStyledButton: FTBaseButton {
    
    @IBInspectable var localizationKey: String?
    @IBInspectable var style: Int = 0;
    @IBInspectable var rounderCorner: CGFloat = 0;
    @IBInspectable var borderWidth: CGFloat = 0;
    @IBInspectable var borderColor: UIColor = UIColor.black;
    
    fileprivate func styleFont() -> UIFont
    {
        let buttonStyle = FTButtonStyle.init(rawValue: style);
        var font : UIFont!;
        switch buttonStyle! {
        case .defaultStyle: //0
            font = UIFont.appFont(for: .regular, with: 16)
        case .style1: //1
            font = UIFont.appFont(for: .regular, with: 15)
        case .style2: //2
            font = UIFont.appFont(for: .regular, with: 17)
        case .style3: //3
            font = UIFont.appFont(for: .regular, with: 11)
        case .style4: //4
            font = UIFont.appFont(for: .regular, with: 19)
        case .style5: //5
            font = UIFont.appFont(for: .regular, with: 19)
        case .style6: //6
            font = UIFont.appFont(for: .regular, with: 12)
        case .style7: //7
            font = UIFont.appFont(for: .regular, with: 22)
        case .style8: //8
            font = UIFont.appFont(for: .regular, with: 13)
        case .style9: //9
            font = UIFont.appFont(for: .bold, with: 16)
        case .style10: //10
            font = UIFont.appFont(for: .bold, with: 14)
        case .style11: //11
            font = UIFont.appFont(for: .regular, with: 14)
        case .style12: //22 montserrat-extra light
            font = UIFont.montserratFont(for: .extraLight, with: 22)
        case .style13: //13
            font = UIFont.appFont(for: .medium, with: 15)
        case .style14: //14
            font = UIFont.appFont(for: .medium, with: 19)
        case .style15: //15
            font = UIFont.appFont(for: .semibold, with: 19)
        case .style16: //15
            font = UIFont.appFont(for: .semibold, with: 17)
        }
        return font;
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if let localizationKey = self.localizationKey {
            let title = self.title(for: .normal);
            self.setStyleTitle(NSLocalizedString(localizationKey, comment: title ?? ""), for: .normal);
        }
        if(self.rounderCorner>0){
            self.layer.cornerRadius = self.rounderCorner
            self.layer.borderWidth = self.borderWidth
            self.layer.borderColor = self.borderColor.cgColor
        }
    }
    
    @objc func setStyleTitle(_ title: String?, for state: UIControl.State) {
        if(nil != title) {
            var titleColor = self.titleColor(for : state);
            if(nil == titleColor) {
                titleColor = UIColor.white;
            }
            let attrTitle = NSAttributedString.init(string: title!, attributes: [NSAttributedString.Key.font:self.styleFont(),NSAttributedString.Key.foregroundColor : titleColor!,NSAttributedString.Key.kern : NSNumber.init(value: defaultKernValue)]);
            self.setAttributedTitle(attrTitle, for: state);
            if(title == ""){
                self.setTitle("", for: UIControl.State.normal)
            }
        }
        else {
            self.setAttributedTitle(nil, for: state);
        }
    }
}
