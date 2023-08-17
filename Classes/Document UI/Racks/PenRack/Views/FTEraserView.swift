//
//  FTEraserView.swift
//  Noteshelf
//
//  Created by Siva on 12/10/17.
//  Copyright © 2017 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

 public class FTEraserView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.layer.borderColor = UIColor.black.withAlphaComponent(0.5).cgColor
        self.layer.borderWidth = 1
        self.backgroundColor = UIColor.white.withAlphaComponent(0.4)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    public override var frame: CGRect {
        didSet {
            self.layer.cornerRadius = self.frame.width / 2
        }
    }
}

@objc public enum FTEraseSize: Int {
    case auto
    case small = 20
    case medium = 34
    case large = 44

    var selectionBorderWidth: CGFloat {
        var width: CGFloat = 0.0
        if self == .small {
            width = 4.0
        } else if self == .medium {
            width = 5.0
        } else if self == .large {
            width = 6.0
        }
        return width
    }

    var selectedImage: UIImage? {
        var img: UIImage?
        if self == .small {
            img = UIImage(named: "eraser_small")
        } else if self == .medium {
            img = UIImage(named: "eraser_medium")
        } else if self == .large {
            img = UIImage(named: "eraser_large")
        }
        return img
    }

    var titleTextColor: UIColor {
        var color: UIColor = .clear
        if self == .auto {
            color = UIColor.label
        }
        return color
    }
}

@objc public class FTEraserSizeView: UIView {
    @IBOutlet weak internal var sizeButton: UIButton!
    var size: FTEraseSize = .auto

    var isSelected: Bool = false {
        didSet {
            if isSelected {
                self.sizeButton.backgroundColor = UIColor.appColor(.white100)
                self.sizeButton.layer.cornerRadius = self.sizeButton.frame.height/2.0
                self.sizeButton.dropShadowWith(color: UIColor.black.withAlphaComponent(0.12), offset: CGSize(width: 0.0, height: 4.0), radius: 8.0)
                self.sizeButton.setTitleColor(size.titleTextColor, for: .normal)
                self.sizeButton.setImage(size.selectedImage, for: .normal)
            } else {
                self.sizeButton.backgroundColor = UIColor.appColor(.eraserBtnUnselected)
                self.sizeButton.removeShadow()
                self.sizeButton.setTitleColor(size.titleTextColor.withAlphaComponent(0.5), for: .normal)
                self.sizeButton.setImage(nil, for: .normal)
            }
        }
    }
}
