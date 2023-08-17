//
//  FTThemeColorCollectionViewCell.swift
//  Noteshelf
//
//  Created by Matra on 16/01/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon

// It is used to create auto theme which is defualt theme and showing as first one in list
class FTAutoThemeView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let lightColor = UIColor(red:249.0/255, green:249.0/255, blue:249.0/255, alpha: 0.94)
        let darkColor = UIColor(red:29.0/255, green:29.0/255, blue: 29.0/255, alpha: 0.94)

        let topRect = CGRect(x: 0, y: 0, width: rect.size.width/2, height: rect.size.height)
        lightColor.set()
        guard let topContext = UIGraphicsGetCurrentContext() else { return }
        topContext.fill(topRect)

        let bottomRect = CGRect(x: rect.size.width/2, y: 0, width: rect.size.width/2, height: rect.size.height)
        darkColor.set()
        guard let bottomContext = UIGraphicsGetCurrentContext() else { return }
        bottomContext.fill(bottomRect)
    }
}

class FTThemeColorCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shelfThemeView: UIView!
    @IBOutlet weak var themeContainerView: UIView?
    @IBOutlet weak var radioImageView: UIImageView?
    @IBOutlet weak var verticalDivider: UIView?
    @IBOutlet weak var themeTitleLabel: UILabel?
    @IBOutlet weak var horizantalDivider: UIView?
    
    var isItemSelected: Bool  = false {
        didSet {
            radioImageView?.image = isItemSelected ? UIImage.init(named: "iconCheckBadge")  : nil
            let borderColor = isItemSelected ? UIColor.clear  : UIColor.appColor(.black50)
            radioImageView?.setBorderColor(withBorderWidth: 1.0, withColor: borderColor)
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        runInMainThread {
            self.themeContainerView?.roundCorners(corners: [.bottomLeft,.bottomRight,.topLeft,.topRight], radius: 8)
        }
        if radioImageView != nil {
            radioImageView?.layer.cornerRadius = radioImageView!.bounds.width/2
            radioImageView?.setBorderColor(withBorderWidth: 1.0, withColor: UIColor.appColor(.black50))
        }
    }
    
    func configureShelfThemeView(theme: FTShelfThemeStyle) {
        self.themeTitleLabel?.text = theme.getLocalizedTitleOfTheme()
        if theme.isAutoTheme() {
            self.shelfThemeView.backgroundColor = .clear
            self.layoutIfNeeded()
            self.shelfThemeView.addSubview(FTAutoThemeView(frame: self.shelfThemeView.bounds))
            self.verticalDivider?.isHidden = false
            self.horizantalDivider?.isHidden = false
        } else {
            self.shelfThemeView.backgroundColor = theme.swatchColor
            self.verticalDivider?.isHidden = true
            self.horizantalDivider?.isHidden = true
            for subView in self.shelfThemeView.subviews where subView is FTAutoThemeView {
                subView.removeFromSuperview()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.layoutIfNeeded()
        self.themeContainerView?.roundCorners(corners: [.bottomLeft,.bottomRight,.topLeft,.topRight], radius: 8)
    }
}
