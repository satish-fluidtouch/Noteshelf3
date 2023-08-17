//
//  FTNS1MigrationInfoView.swift
//  Noteshelf
//
//  Created by Amar on 22/08/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

class FTNS1MigrationInfoView: UIView {

    @IBOutlet weak var infoLabel : FTStyledLabel!;
    fileprivate var layoutManager = NSLayoutManager();
    fileprivate var textStorage : NSTextStorage!;
    fileprivate var textContainer : NSTextContainer!;

    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor = UIColor.appColor(.secondaryBG);
        let label = FTStyledLabel.init(frame: self.bounds);
        label.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,UIView.AutoresizingMask.flexibleHeight];
        label.textAlignment = .center;
        self.addSubview(label);
        self.infoLabel = label;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    override func awakeFromNib() {
        let stringToAdd = NSLocalizedString("SystemGeneratedCollectionWarning", comment: "This is a system generated category...");
        self.updateInfoString(stringToAdd)
    }
    
    @objc func updateInfoString(_ stringToAdd : String) {
        let mutableAttributedtext = NSMutableAttributedString.init(string: stringToAdd, attributes: [NSAttributedString.Key.font:UIFont.appFont(for: .regular, with: 12),NSAttributedString.Key.foregroundColor:UIColor.headerColor]);
        mutableAttributedtext.append(NSAttributedString.init(string: " ", attributes: [NSAttributedString.Key.font:UIFont.appFont(for: .regular, with: 12),NSAttributedString.Key.foregroundColor:UIColor.headerColor]));
        
        let learnmoreAttributedText = NSAttributedString.init(string: NSLocalizedString("LearnMore", comment: "Learn More"), attributes: [NSAttributedString.Key.font:UIFont.appFont(for: .regular, with: 12),NSAttributedString.Key.link : URL.init(string: "http://www.noteshelf.net/")!,NSAttributedString.Key.foregroundColor:UIColor.appColor(.accent)]);
        mutableAttributedtext.append(learnmoreAttributedText)
        self.infoLabel.styledAttributedText = mutableAttributedtext;
        
        let gesture = UITapGestureRecognizer.init(target: self, action: #selector(FTNS1MigrationInfoView.didTapOnGesture(gesture:)));
        self.addGestureRecognizer(gesture);
        
        // Configure layoutManager and textStorage
        self.textContainer = NSTextContainer.init(size: CGSize.zero);
        self.textStorage = NSTextStorage.init(attributedString: mutableAttributedtext);
        self.layoutManager.addTextContainer(self.textContainer);
        self.textStorage.addLayoutManager(self.layoutManager);
        
        // Configure textContainer
        self.textContainer.lineFragmentPadding = 0.0;
        self.textContainer.lineBreakMode = self.infoLabel.lineBreakMode;
        self.textContainer.maximumNumberOfLines = self.infoLabel.numberOfLines;
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        self.textContainer.size = self.infoLabel.bounds.size;
    }
    
    @objc func didTapOnGesture(gesture : UITapGestureRecognizer)
    {
        let locationOfTouchInLabel = gesture.location(in: self.infoLabel);
        let labelSize = gesture.view!.bounds.size;
        let textBoundingBox = self.layoutManager.usedRect(for: self.textContainer);
        let textContainerOffset = CGPoint.init(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                               y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let locationOfTouchInTextContainer = CGPoint.init(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                          y: locationOfTouchInLabel.y - textContainerOffset.y)
        
        let glyphIndex = self.layoutManager.glyphIndex(for: locationOfTouchInTextContainer, in: self.textContainer);
        let indexOfCharacter = self.layoutManager.characterIndexForGlyph(at: glyphIndex);
       
        let attributes = self.infoLabel.styledAttributedText?.attributes(at: indexOfCharacter, effectiveRange: nil);
        if(attributes?[NSAttributedString.Key.link] != nil) {
            FTZenDeskManager.shared.showArticle("235408087", in: self.window?.visibleViewController, completion: nil);
        }
    }
}
