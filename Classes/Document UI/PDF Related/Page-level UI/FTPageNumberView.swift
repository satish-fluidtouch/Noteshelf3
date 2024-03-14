//
//  FTPageNumberView.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles
import FTCommon

@objcMembers class FTPageNumberView : UIVisualEffectView {
    
    fileprivate var pageNumberInfoLabel : UILabel = UILabel()
    fileprivate var page : FTPageProtocol?

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
    }
    convenience init(effect: UIVisualEffect,frame: CGRect, page : FTPageProtocol) {
        self.init(effect: effect)
        self.frame = frame
        self.backgroundColor = UIColor.appColor(.regularToolbarBgColor)
        self.clipsToBounds = true
        self.layer.cornerRadius = 6.0
        self.isUserInteractionEnabled = false;
        self.pageNumberInfoLabel = UILabel.init(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height));
        self.pageNumberInfoLabel.center = self.contentView.center
        self.pageNumberInfoLabel.textAlignment = NSTextAlignment.center;
        self.pageNumberInfoLabel.font = UIFont.appFont(for: .medium, with: 15)
        self.pageNumberInfoLabel.layer.cornerRadius = 6.0
        self.pageNumberInfoLabel.layer.masksToBounds = true
        self.contentView.addSubview(self.pageNumberInfoLabel)
        self.contentView.bringSubviewToFront(self.pageNumberInfoLabel)
        self.pageNumberInfoLabel.textColor = UIColor.appColor(.black70)
        self.pageNumberInfoLabel.backgroundColor = .clear
        self.page = page
        self.setCurrentPage(page)
        self.updateTextColor();
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCurrentPage(_ page : FTPageProtocol) {
        self.updateTextColor();
        if let document = page.parentDocument {
            let attributedPageNumberInfo = NSAttributedString(string: String.init(format: NSLocalizedString("NofNAlt", comment: "%d of %d"),page.pageIndex()+1,document.pages().count))

            let pageNumberInfo = attributedPageNumberInfo.string
            self.pageNumberInfoLabel.frame.size = CGSize(width: (attributedPageNumberInfo.size().width + 32), height: 24)
            self.pageNumberInfoLabel.text =  pageNumberInfo
        }
        else {
            self.pageNumberInfoLabel.text = "";
        }
        self.setNeedsLayout()
    }
    func udpateLabelFramesYPosition(_ newYPosition: CGFloat) {
        var labelFrame = self.frame;
        labelFrame.origin.y = newYPosition;
        labelFrame.size = CGSize(width: ((pageNumberInfoLabel.text?.size().width ?? 0) + 32), height: 24)
        self.frame = labelFrame
    }
    
    private func updateTextColor()
    {
        guard ((page?.templateInfo.isTemplate) != nil) ,
            let _page = page as? FTPageBackgroundColorProtocol
            else {
                return;
        }
        _page.pageBackgroundColor { (color) in
            self.pageNumberInfoLabel.textColor = UIColor.appColor(.black70);
        }
    }
}
