//
//  FTPageFooterView.swift
//  Noteshelf
//
//  Created by Amar on 16/6/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles

@objcMembers class FTPageFooterView: UIView {
    
    fileprivate weak var pageInfoLabel : UILabel?;
    fileprivate weak var bookTitleLabel : UILabel?;
    fileprivate weak var page : FTPageProtocol?;
    fileprivate var scale : CGFloat = CGFloat(1);
    
    static let footerHeight : CGFloat = 44;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        
        self.isUserInteractionEnabled = false;
        
        let pageLabel = UILabel.init(frame: CGRect.zero);
        pageLabel.textAlignment = NSTextAlignment.right;
        self.addSubview(pageLabel);
        self.pageInfoLabel = pageLabel;
        self.pageInfoLabel?.textColor = UIColor.black.withAlphaComponent(0.5);

        let bookLabel = FTStyledLabel.init(frame: CGRect.zero);
        self.addSubview(bookLabel);
        self.bookTitleLabel = bookLabel;
        self.bookTitleLabel?.textColor = UIColor.black.withAlphaComponent(0.5);

        self.updateTextColor();
        self.updateFontSize();
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangePageProperties),
                                               name: NSNotification.Name(rawValue: "FTDocumentDidAddedPageIndices"),
                                               object: nil);
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangePageProperties),
                                               name: NSNotification.Name(rawValue: "FTDocumentDidMovedPageIndices"),
                                               object: nil);
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didChangePageProperties),
                                               name: NSNotification.Name(rawValue: "FTDocumentDidRemovePageIndices"),
                                               object: nil);
        // TODO: (Narayana) - for now hiding this, if required we may need to remove this view itself.
        self.bookTitleLabel?.isHidden = true
        self.pageInfoLabel?.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews();
        
        let height = self.bounds.height;
        let width = self.bounds.width;
        if(height.isNaN || width.isNaN || self.scale.isNaN) {
            self.pageInfoLabel?.frame = CGRect.zero;
            self.bookTitleLabel?.frame = CGRect.zero;
            return;
        }
        self.pageInfoLabel?.frame = CGRect.init(x: self.bounds.width - 100*self.scale-18*self.scale,
                                               y: 0,
                                               width: 100*self.scale,
                                               height: height);
        self.bookTitleLabel?.frame = CGRect.init(x: 18*self.scale,
                                               y: 0,
                                               width: 180*self.scale,
                                               height: height);
    }
    
    func setCurrentPage(_ page : FTPageProtocol) {
        self.page = page;
        self.updateTextColor();
        
        if let document = page.parentDocument {
            self.pageInfoLabel?.text = String.init(format: NSLocalizedString("NofNAlt", comment: "%d of %d"),page.pageIndex()+1,document.pages().count);
            self.bookTitleLabel?.text = document.URL.deletingPathExtension().lastPathComponent;
        }
        else {
            self.pageInfoLabel?.text = "";
            self.bookTitleLabel?.text = "";
        }
        self.updateFontSize();
    }
    
    private func updateTextColor()
    {
        guard page?.templateInfo.isTemplate ?? false,
            let _page = page as? FTPageBackgroundColorProtocol
            else {
                return;
        }
        _page.pageBackgroundColor { (color) in
            let textColor = color?.blackOrWhiteContrastingColor() ?? UIColor.black;
            self.pageInfoLabel?.textColor = textColor.withAlphaComponent(0.5);
            self.bookTitleLabel?.textColor = textColor.withAlphaComponent(0.5);
        }
    }
    
    private func updateFontSize()
    {
        let font = self.defaultFooterFont();
        self.pageInfoLabel?.font = font.withSize(font.pointSize*self.scale);
        self.bookTitleLabel?.font = font.withSize(font.pointSize*self.scale);
    }
    func applyScale(_ inScale : CGFloat) {
        if(self.scale != inScale) {
            self.scale = inScale;
            self.setNeedsLayout();
            self.updateFontSize();
        }
    }
    
    @objc func didChangePageProperties()
    {
        if(nil != self.page) {
            self.setCurrentPage(self.page!);
        }
    }
    
    fileprivate func defaultFooterFont() -> UIFont
    {
        return UIFont.appFont(for: .regular, with: 12)
    }
}
