//
//  FTClipartCell.swift
//  ClipartKit
//
//  Created by Akshay on 27/11/18.
//  Copyright © 2018 FluidTouch. All rights reserved.
//

import UIKit
import SDWebImage

class FTMediaLibraryCell: UICollectionViewCell {
    @IBOutlet weak var thumbnail:UIImageView!
    @IBOutlet weak var deleteButton:UIButton?
    
    @IBOutlet weak var photographerLbl: UILabel?
    @IBOutlet weak var nameHeightConstraint: NSLayoutConstraint!
    
    fileprivate var clipart : FTMediaLibraryModel?
    private var screenScale: CGFloat { return UIScreen.main.scale }

    var deleteLocalClipart:((FTMediaLibraryModel)->Void)?
    
    func configure(with clipart:FTMediaLibraryModel, isEditing: Bool) {
        self.thumbnail.backgroundColor = .clear
        self.clipart = clipart
        if self.clipart?.clipartDescription == "UnSplash" {
            if let photographer = self.clipart?.user?.name {
                photographerLbl?.textColor = UIColor.label
                let attributedString = NSMutableAttributedString()
                attributedString.append(NSAttributedString(string: "by ",
                                                           attributes: [.underlineStyle: 0]))
                attributedString.append(NSAttributedString(string: photographer,
                                                           attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]))
                photographerLbl?.attributedText = attributedString
                nameHeightConstraint.constant = 25
                
                let labelTap = UITapGestureRecognizer(target: self, action: #selector(self.photographerNameTapped(_:)))
                photographerLbl?.isUserInteractionEnabled = true
                photographerLbl?.addGestureRecognizer(labelTap)
            }
            else {
                photographerLbl?.text = ""
                nameHeightConstraint.constant = 0
            }
        }
        else {
            photographerLbl?.text = ""
            nameHeightConstraint.constant = 0
        }
        deleteButton?.isHidden = true
        
        thumbnail.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        thumbnail.contentMode = .center
        thumbnail.clipsToBounds = true

        thumbnail.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        guard let urlString = clipart.urls?.png_thumb, let url = URL(string: urlString) else {
            return
        }

        thumbnail.sd_setImage(with: url, placeholderImage:nil, options: SDWebImageOptions.refreshCached, completed: { [weak self] (image, error, _, _) -> Void in
            if ((error) == nil) {
                self?.thumbnail.image = image
                self?.thumbnail.contentMode = .scaleAspectFill
                self?.thumbnail.backgroundColor = UIColor.clear
            }
        })

         if isEditing {
            deleteButton?.isHidden = !isEditing
            self.startWiggle()
        } else {
            self.stopWiggle()
        }
    }

    @IBAction func deleteButtonTapped(sender:UIButton) {
        guard let recentClipart = clipart else { return }
        deleteLocalClipart?(recentClipart)
    }
    @objc func startWiggle(_ notification:Notification) {
        // Do something now
        deleteButton?.isHidden = false
        self.startWiggle()
    }
    @objc func stopWiggle(_ notification:Notification) {
          // Do something now
        deleteButton?.isHidden = true
          self.stopWiggle()
      }
    @objc func photographerNameTapped(_ sender: UITapGestureRecognizer) {
        if let user = self.clipart?.user, let photographerUrl = user.links?.html {
            if let url = URL(string: photographerUrl) {
                UIApplication.shared.open(url)
            }
        }
    }

}


