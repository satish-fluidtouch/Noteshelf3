//
//  FTTextInputFontStyleViewController.swift
//  Noteshelf
//
//  Created by Amar on 20/5/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

enum FTFontStyle : Int
{
    case bold
    case italic
    case underline
    case headerStyle1
    case headerStyle2
    case headerStyle3
    case bodyStyle
}

protocol FTTextInputFontStyleDelegate : class {
    func textInputFontStyle(_ viewController : FTTextInputFontStyleViewController,didTapOnFontStyle style : FTFontStyle);
}

class FTTextInputFontStyleViewController: UIViewController,FTTextInputValidationProtocol {

    fileprivate weak var delegate : FTTextInputFontStyleDelegate?;
    fileprivate var fontStyle : FTFontStyles!;

    @IBOutlet var headerStyle1Button : UIButton?;
    @IBOutlet var headerStyle2Button : UIButton?;
    @IBOutlet var headerStyle3Button : UIButton?;
    @IBOutlet var bodyStyleButton : UIButton?;
    @IBOutlet weak var compactPanelLeadingConstraint : NSLayoutConstraint!;
    @IBOutlet weak var compactPanelTrailingConstraint : NSLayoutConstraint!;

    @IBOutlet var boldButton : UIButton?;
    @IBOutlet var italicButton : UIButton?;
    @IBOutlet var underlingButton : UIButton?;

    class func viewController(_ delegate : FTTextInputFontStyleDelegate,fontStyle : FTFontStyles) -> FTTextInputFontStyleViewController
    {
        let storyboard = UIStoryboard.init(name: "FTTextInputUI", bundle: nil);
        let controller = storyboard.instantiateViewController(withIdentifier: "FTTextInputFontStyleView") as! FTTextInputFontStyleViewController;
        controller.delegate = delegate;
        controller.fontStyle = fontStyle;
        var frame = controller.view.frame;
        frame.size.height = textInputViewHeight;
        controller.view.frame = frame;
        return controller;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.headerStyle1Button?.titleLabel?.font = self.fontStyle.headerStyle1Font;
        self.headerStyle1Button?.setTitle(NSLocalizedString("Header_1", comment: "Header 1"), for: .normal);
        self.headerStyle2Button?.titleLabel?.font = self.fontStyle.headerStyle2Font;
        self.headerStyle2Button?.setTitle(NSLocalizedString("Header_2", comment: "Header 2"), for: .normal);
        self.headerStyle3Button?.titleLabel?.font = self.fontStyle.headerStyle3Font;
        self.headerStyle3Button?.setTitle(NSLocalizedString("Header_3", comment: "Header 3"), for: .normal);
        self.bodyStyleButton?.titleLabel?.font = FTCustomFontManager.shared.defaultBodyFont;
        self.bodyStyleButton?.setTitle(NSLocalizedString("Body", comment: "Body"), for: .normal);
        
        if(self.isIphoneX()){
            let safeAreaInsets = self.originalSafeAreaInsets()
            self.compactPanelLeadingConstraint.constant = safeAreaInsets.left;
            self.compactPanelTrailingConstraint.constant = safeAreaInsets.right;
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapOnBold(_ sender : UIButton) {
        self.delegate?.textInputFontStyle(self, didTapOnFontStyle: .bold);
    }
    
    @IBAction func didTapOnItalic(_ sender : UIButton) {
        self.delegate?.textInputFontStyle(self, didTapOnFontStyle: .italic);
    }

    @IBAction func didTapOnUnderline(_ sender : UIButton) {
        self.delegate?.textInputFontStyle(self, didTapOnFontStyle: .underline);
    }

    @IBAction func didTapOnHeaderStyle1(_ sender : UIButton) {
        self.delegate?.textInputFontStyle(self, didTapOnFontStyle: .headerStyle1);
    }

    @IBAction func didTapOnHeaderStyle2(_ sender : UIButton) {
        self.delegate?.textInputFontStyle(self, didTapOnFontStyle: .headerStyle2);
    }

    @IBAction func didTapOnHeaderStyle3(_ sender : UIButton) {
        self.delegate?.textInputFontStyle(self, didTapOnFontStyle: .headerStyle3);
    }
    
    @IBAction func didTapOnBodyStyle(_ sender : UIButton) {
        self.delegate?.textInputFontStyle(self, didTapOnFontStyle: .bodyStyle);
    }

    func validateKeyboard(attributes : [NSAttributedString.Key:Any],scale : CGFloat)
    {
        self.headerStyle1Button?.backgroundColor = UIColor.clear;
        self.headerStyle2Button?.backgroundColor = UIColor.clear;
        self.headerStyle3Button?.backgroundColor = UIColor.clear;
        self.bodyStyleButton?.backgroundColor = UIColor.clear;
        self.boldButton?.backgroundColor = UIColor.clear;
        self.italicButton?.backgroundColor = UIColor.clear;
        self.underlingButton?.backgroundColor = UIColor.clear;
        
        var font = attributes[NSAttributedString.Key.font] as! UIFont;
        let originalFont = attributes[NSAttributedString.Key(rawValue:"NSOriginalFont")] as? UIFont;
        if(nil != originalFont) {
            font = originalFont!;
        }

        let fontName = font.fontName;
        let pointSize = roundOf2Digits(Float(font.pointSize));
        
        if(self.fontStyle.headerStyle1Font.fontName == fontName && CGFloat(pointSize) == self.fontStyle.headerStyle1Font.pointSize) {
            self.headerStyle1Button?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        }
        else if(self.fontStyle.headerStyle2Font.fontName == fontName && CGFloat(pointSize) == self.fontStyle.headerStyle2Font.pointSize) {
            self.headerStyle2Button?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        }
        else if(self.fontStyle.headerStyle3Font.fontName == fontName && CGFloat(pointSize) == self.fontStyle.headerStyle3Font.pointSize) {
            self.headerStyle3Button?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        }
        else if(FTCustomFontManager.shared.defaultBodyFont.fontName == fontName && CGFloat(pointSize) == FTCustomFontManager.shared.defaultBodyFont.pointSize) {
            self.bodyStyleButton?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        }

        
        if(font.isBoldTrait()) {
            self.boldButton?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        }
        if(font.isItalic()) {
            self.italicButton?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        }
        if(nil != attributes[NSAttributedString.Key.underlineStyle]) {
            self.underlingButton?.backgroundColor = UIColor.black.withAlphaComponent(0.1);
        }
    }
}
