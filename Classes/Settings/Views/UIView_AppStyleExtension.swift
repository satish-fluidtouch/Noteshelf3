//
//  UITableViewCell_AppStyleExtension.swift
//  Noteshelf
//
//  Created by Amar on 13/7/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objc enum FTTableViewCellStyle : Int
{
    case defaultStyle
    case style1
}

extension UITableViewCell {

    fileprivate func fontForStyle(_ style : FTTableViewCellStyle) -> UIFont
    {
        var font : UIFont!;
        switch style {
        case .defaultStyle:
            font = UIFont.appFont(for: .regular, with: 16)
        case .style1:
            font = UIFont.appFont(for: .regular, with: 14)
        }
        return font;
    }
    
    @objc func setStyledText(_ text : String,style : FTTableViewCellStyle)
    {
        let font = self.fontForStyle(style);
        self.textLabel?.attributedText = NSAttributedString.init(string: text, attributes: [NSAttributedString.Key.kern : NSNumber.init(value: defaultKernValue),NSAttributedString.Key.font : font, .foregroundColor: UIColor.label]);
    }
    
    func setStyledDetailText(_ text : String,style : FTTableViewCellStyle)
    {
        let font = self.fontForStyle(style);
        self.detailTextLabel?.attributedText = NSAttributedString.init(string: text, attributes: [NSAttributedString.Key.kern : NSNumber.init(value: defaultKernValue),NSAttributedString.Key.font : font, .foregroundColor: UIColor.label]);
    }
}

@objc enum FTTextViewStyle : Int
{
    case defaultStyle
}

extension UITextView
{
    fileprivate func styleInfo(_ style : FTTextViewStyle) -> [NSAttributedString.Key : AnyObject] {
        var info = [NSAttributedString.Key : AnyObject]();
        switch style {
        case .defaultStyle:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 17)
        }
        info[NSAttributedString.Key.kern] = NSNumber.init(value: defaultKernValue);
        return info;
    }
    
    func setDefaultStyle(_ style : FTTextViewStyle) {
        var styleInfo = self.styleInfo(style);
        self.font = styleInfo[NSAttributedString.Key.font] as? UIFont;
        let color = styleInfo[NSAttributedString.Key.foregroundColor];
        if(nil == color) {
            styleInfo[NSAttributedString.Key.foregroundColor] = self.textColor;
        }
        self.typingAttributes = styleInfo;
    }
    
    func setStyledText(_ string : String) {
        self.attributedText = NSAttributedString.init(string: string);
    }
}

@objc enum FTTextFieldStyle : Int
{
    case defaultStyle
    case style1
    case style2
    case style3
    case style4
}

@objc enum FTTextFieldPlaceHolderStyle : Int
{
    case defaultStyle
    case style1
    case style2
    case style3
    case style4
    case style5
    case style6
    case style7
    case style8
    case style9
}

extension UITextField
{
    fileprivate func styleInfo(_ style : FTTextFieldStyle) -> [NSAttributedString.Key : AnyObject] {
        var info = [NSAttributedString.Key : AnyObject]();
        switch style {
        case .defaultStyle:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 16)
        case .style1:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 15)
        case .style2:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
        case .style3:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 11)
        case .style4:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 17)
        }
        info[NSAttributedString.Key.kern] = NSNumber.init(value: defaultKernValue);
        return info;
    }
    
    fileprivate func placeholderStyleInfo(_ style : FTTextFieldPlaceHolderStyle) -> [NSAttributedString.Key : AnyObject] {
        var info = [NSAttributedString.Key : AnyObject]();
        switch style {
        case .defaultStyle:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 16)
            info[NSAttributedString.Key.foregroundColor] = UIColor.appColor(.black50);
        case .style1:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 16)
            info[NSAttributedString.Key.foregroundColor] = UIColor.appColor(.black50);
        case .style2:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 15)
            info[NSAttributedString.Key.foregroundColor] = UIColor.init(hexString:"000000").withAlphaComponent(0.5);
        case .style3:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
            info[NSAttributedString.Key.foregroundColor] = UIColor.white.withAlphaComponent(0.5);
        case .style4:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 17)
            info[NSAttributedString.Key.foregroundColor] = UIColor.appColor(.black30);
        case .style5:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 16)
            info[NSAttributedString.Key.foregroundColor] = UIColor.appColor(.black50);
        case .style6:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
            info[NSAttributedString.Key.foregroundColor] = UIColor.init(hexString: "383838").withAlphaComponent(0.5);
        case .style7:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 16)
            info[NSAttributedString.Key.foregroundColor] = UIColor.appColor(.black50)
        case .style8:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 16)
            info[NSAttributedString.Key.foregroundColor] = UIColor.white;
        case .style9:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 13)
            info[NSAttributedString.Key.foregroundColor] = UIColor.headerColor
        }
        info[NSAttributedString.Key.kern] = NSNumber.init(value: defaultKernValue);
        return info;
    }

    @objc func setDefaultStyle(_ style : FTTextFieldStyle, kernValue: Double = 0) {
        var styleInfo = self.styleInfo(style);
        self.font = styleInfo[NSAttributedString.Key.font] as? UIFont;
        styleInfo[NSAttributedString.Key.foregroundColor] = UIColor.headerColor
        styleInfo[NSAttributedString.Key.kern] = NSNumber.init(value: kernValue)
        if self.textAlignment == .center {
            let paragraphStyle = NSMutableParagraphStyle();
            paragraphStyle.alignment = .center;
            styleInfo[NSAttributedString.Key.paragraphStyle] = paragraphStyle;
        }
        self.defaultTextAttributes = styleInfo;
    }
    
    func setStyledText(_ string : String) {
        self.attributedText = NSAttributedString.init(string: string);
    }

    @objc func setStyledPlaceHolder(_ placeHolder : String,style : FTTextFieldPlaceHolderStyle)
    {
        let styleInfo = self.placeholderStyleInfo(style);
        self.attributedPlaceholder = NSAttributedString.init(string: placeHolder, attributes: styleInfo);
    }
}

@objc enum FTSegmentedControlStyle : Int
{
    case defaultStyle
    case style1
    case style2
    case style3
    case style4
    case style5
}

extension UISegmentedControl
{
    fileprivate func styleInfo(_ style : FTSegmentedControlStyle) -> [NSAttributedString.Key : AnyObject] {
        var info = [NSAttributedString.Key : AnyObject]();
        switch style {
        case .defaultStyle:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
            info[NSAttributedString.Key.foregroundColor] = UIColor.white;
        case .style1:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
            info[NSAttributedString.Key.foregroundColor] = UIColor.black.withAlphaComponent(0.15);
        case .style2:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
            info[NSAttributedString.Key.foregroundColor] = UIColor.white.withAlphaComponent(0.5);
        case .style3:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
        case .style4:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
            info[NSAttributedString.Key.foregroundColor] = UIColor.init(hexString: "78b2cc");
        case .style5:
            info[NSAttributedString.Key.font] = UIFont.appFont(for: .regular, with: 14)
            info[NSAttributedString.Key.foregroundColor] = UIColor.black.withAlphaComponent(0.3);
        }
        info[NSAttributedString.Key.kern] = NSNumber.init(value: defaultKernValue);
        return info;
    }

    @objc func setStyle(_ style : FTSegmentedControlStyle,forState state : UIControl.State,textColor : UIColor? = nil)
    {
        var styleInfo = self.styleInfo(style);
        if(nil != textColor) {
            styleInfo[NSAttributedString.Key.foregroundColor] = textColor!;
        }
        self.setTitleTextAttributes(styleInfo, for: state);
    }
}
