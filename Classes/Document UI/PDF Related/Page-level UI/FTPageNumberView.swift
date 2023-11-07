//
//  FTPageNumberView.swift
//  Noteshelf
//
//  Created by Ramakrishna on 09/05/21.
//  Copyright © 2021 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTStyles

@objcMembers class FTPageNumberView : UIView {
    
    fileprivate weak var pageNumberInfoLabel : UILabel?
    fileprivate var page : FTPageProtocol?
    fileprivate var labelFrame: CGRect = .zero
    fileprivate let visualEffectView = UIVisualEffectView()
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    convenience init(frame: CGRect, page : FTPageProtocol) {
        self.init()
        self.isUserInteractionEnabled = false;
        let pageLabel = UILabel.init(frame: frame);
        pageLabel.textAlignment = NSTextAlignment.center;
        pageLabel.font = UIFont.appFont(for: .medium, with: 15)
        pageLabel.layer.cornerRadius = 6.0
        visualEffectView.frame = frame
        visualEffectView.effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .regular),style: UIVibrancyEffectStyle.label)
        visualEffectView.backgroundColor = UIColor.init(hexString: "#E5E5E5",alpha: 1.0)
        visualEffectView.layer.cornerRadius = 6.0
        pageLabel.layer.masksToBounds = true
        self.addSubview(visualEffectView)
        self.addSubview(pageLabel)
        pageLabel.bringSubviewToFront(self)
        self.pageNumberInfoLabel = pageLabel
        self.pageNumberInfoLabel?.textColor = UIColor.appColor(.black70)
        self.page = page
        self.labelFrame = frame
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
            let newFrame = CGRect(x:labelFrame.minX,y: labelFrame.minY,width: (attributedPageNumberInfo.size().width + 32), height: 24)
            self.pageNumberInfoLabel?.frame = newFrame
            visualEffectView.frame = newFrame
            self.pageNumberInfoLabel?.text =  pageNumberInfo
        }
        else {
            self.pageNumberInfoLabel?.text = "";
        }
        self.setNeedsLayout()
    }
    func udpateLabelFramesYPosition(_ newYPosition: CGFloat) {
        self.labelFrame.origin = CGPoint(x: self.labelFrame.minX, y: newYPosition)
        let newFrame = CGRect(x: labelFrame.minX, y: labelFrame.minY, width: ((pageNumberInfoLabel?.text?.size().width ?? 0) + 32), height: 24)
        self.pageNumberInfoLabel?.frame = newFrame
        visualEffectView.frame = newFrame
        self.setNeedsLayout()
    }
    
    private func updateTextColor()
    {
        guard ((page?.templateInfo.isTemplate) != nil) ,
            let _page = page as? FTPageBackgroundColorProtocol
            else {
                return;
        }
        _page.pageBackgroundColor { (color) in
            self.pageNumberInfoLabel?.textColor = UIColor.black.withAlphaComponent(0.7);
        }
    }
}
