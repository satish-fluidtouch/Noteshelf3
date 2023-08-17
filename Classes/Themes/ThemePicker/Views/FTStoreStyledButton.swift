//
//  FTStoreStyledButton.swift
//  Noteshelf
//
//  Created by Amar on 12/04/18.
//  Copyright © 2018 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTStyles
import FTCommon

private extension UIColor {

    @nonobjc class var normalBackground: UIColor {
        return UIColor.clear
    }

    @nonobjc class var downloadedBackground: UIColor {
        return UIColor.label.withAlphaComponent(0.10)
    }

    @nonobjc class var downloadingBackground: UIColor {
        return UIColor.clear
    }

    @nonobjc class var updateBackground: UIColor {
        return UIColor.clear
    }

}

class FTStoreStyledButton: FTStyledButton {
    @IBOutlet weak var widthconstraint: NSLayoutConstraint?
    private weak var circularProgressView: RPCircularProgress?;
    private var fillImageVertically = false;

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += 40
        return size
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.backgroundColor = .clear
        self.style = FTButtonStyle.style11.rawValue
    }
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        FTBaseButton.applyPointInteraction(to: self)
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var rect = super.imageRect(forContentRect: contentRect);
        if(self.fillImageVertically) {
            let ratio = rect.width / rect.height;
            rect.size.height = self.bounds.height;
            rect.size.width = ratio * rect.size.height;
            rect.origin.y = 0;
            rect.origin.x = (self.bounds.width - rect.size.width) * 0.5;
        }
        return rect;
    }

    func update(forThemeBanner themeBanner: FTThemeBanner, notification: Notification?, isSmallPack: Bool = false) {
        self.fillImageVertically = false;
        var title: String = "  " //Should not be blank to avoid crash while hovering mouse
        var isBtnEnabled = true

        let bgColor: UIColor
        var borderColor : UIColor = UIColor.appColor(.accent)

        switch themeBanner.downloadStatus {
        case .downloading:
            bgColor = .downloadingBackground
            borderColor = .clear
            isBtnEnabled = false
            if let progressView = self.circularProgressView {
                if let notification = notification,
                    nil != notification.userInfo,
                    let value = notification.userInfo!["Progress"] as? NSNumber,
                    value.floatValue > 0 {
                    progressView.updateProgress(CGFloat(value.floatValue / 100.0), animated: true, initialDelay: 0, duration: 0, completion: nil)
                }

            } else {
                let progressView = RPCircularProgress()
                self.circularProgressView = progressView;
                let progressSize: CGFloat = self.bounds.height
                let x = self.bounds.origin.x + (self.bounds.width - progressSize) / 2
                let y = self.bounds.origin.y + (self.bounds.height - progressSize) / 2
                progressView.frame = CGRect(x: x, y: y, width: progressSize, height: progressSize)
                progressView.thicknessRatio = 0.30
                progressView.progressTintColor = .appColor(.accent)
                progressView.trackTintColor = .downloadedBackground
                self.addSubview(progressView)
            }
        case .downloaded:
            borderColor = .appColor(.accent)
            bgColor = .clear
            self.setTitleColor(.appColor(.accent), for: .normal)
            let titleText = NSMutableAttributedString(string: NSLocalizedString("Updated", comment: "Updated"), attributes: [.font: UIFont.appFont(for: .semibold, with: 15.0)])
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "iconCheckBadge")
            attachment.bounds = CGRect.init(x: 0, y: -3, width: 16.0, height: 16.0)
            let imgStr = NSMutableAttributedString(attachment: attachment)
            titleText.append(NSAttributedString(string: " "))
            titleText.append(imgStr)
            self.setAttributedTitle(titleText, for: .normal)
            self.widthconstraint?.constant = titleText.size().width + 30.0
            self.removeProgress()
        case .updateAvailable:
            bgColor = .appColor(.accent)
            self.setTitleColor(.white, for: .normal)
            let titleText = NSMutableAttributedString(string: NSLocalizedString("Update", comment: "Update"), attributes: [.font: UIFont.appFont(for: .semibold, with: 15.0)])
            self.setAttributedTitle(titleText, for: .normal)
            self.widthconstraint?.constant = titleText.size().width + 30.0
            self.removeProgress()
        case .none:
            bgColor = .normalBackground
            title = themeBanner.getString
            self.removeProgress()
            self.accessibilityLabel = title;
            borderColor = UIColor.appColor(.accent)
            let titleText = NSMutableAttributedString(string: title, attributes: [.font: UIFont.appFont(for: .semibold, with: 15.0)])
            self.widthconstraint?.constant = titleText.size().width + 40.0
            self.setAttributedTitle(titleText, for: .normal)
        }
        self.isEnabled = isBtnEnabled
        self.backgroundColor = bgColor
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = 1.0
    }

    private func removeProgress() {
        self.circularProgressView?.removeFromSuperview();
        self.circularProgressView = nil;
    }
}

class FTStoreUpdatesButton: FTBaseButton {
    var updatesAvailable: Bool = false {
        didSet {
            if updatesAvailable {
                let dotLayer = CALayer()
                let updateBtnBounds = self.bounds
                dotLayer.frame = CGRect(x: updateBtnBounds.width-15, y: 5, width: 10, height:10)
                dotLayer.backgroundColor = UIColor.appColor(.accent).cgColor
                dotLayer.borderColor = UIColor.appColor(.secondaryBG).cgColor
                dotLayer.borderWidth = 1.0
                dotLayer.cornerRadius = 5.0
                self.layer.addSublayer(dotLayer)
            } else {
                if let subLayers = self.layer.sublayers, subLayers.count > 1, let dotLayer = subLayers.last {
                    dotLayer.removeFromSuperlayer()
                }
            }
        }
    }
}
