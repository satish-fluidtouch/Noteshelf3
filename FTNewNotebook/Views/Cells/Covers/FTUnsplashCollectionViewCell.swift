//
//  FTUNsplashCollectionViewCell.swift
//  FTNewNotebook
//
//  Created by Narayana on 14/03/23.
//

import UIKit
import FTCommon
import SDWebImage

public enum FTUnsplashMode: String {
    case newNotebook
    case addMenu
}

public class FTUnsplashCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var selectImage: UIImageView!
    @IBOutlet private weak var shadowView: UIView!

    private var currentItem: FTUnSplashItem?
    private var mode: FTUnsplashMode = .addMenu
    private let indicator = SDWebImageActivityIndicator.medium

    private var isDownLoading: Bool = false {
        didSet {
            if isDownLoading {
                self.imageView.layer.borderColor = UIColor.label.withAlphaComponent(0.3).cgColor
                self.imageView.layer.borderWidth = 0.5
                self.imageView.sd_imageIndicator = indicator
            } else {
                self.imageView.layer.borderWidth = 0.0
                self.imageView.sd_imageIndicator = nil
            }
        }
    }

    public override var isSelected: Bool {
        didSet {
            self.selectImage.isHidden = !self.isSelected
            if self.mode == .newNotebook {
                self.imageView.layer.borderWidth = isSelected ? 3.0 : 0.0
                self.imageView.layer.borderColor = UIColor.appColor(.accent).cgColor
            }
        }
    }

    public func configure(with item: FTUnSplashItem, mode: FTUnsplashMode = .addMenu) {
        if(currentItem?.id == item.id) {
            return
        }
        self.mode = mode
        self.configureExtraUI(for: mode)
        currentItem = item
        self.imageView?.image = nil
        self.selectImage.isHidden = !self.isSelected
        if let urlStr = item.urls?.thumb, let reqUrl = URL(string: urlStr) {
            self.isDownLoading = true
            self.imageView.sd_setImage(with: reqUrl,
                                  placeholderImage: nil,
                                       options: [SDWebImageOptions.refreshCached],
                                  completed: { img, error, cacheType, _ in
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    return
                }
                self.isDownLoading = false
                self.imageView.image = img
            })
        }
    }

    private func configureExtraUI(for mode: FTUnsplashMode) {
        self.imageView.contentMode = .center
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if mode == .newNotebook {
            self.imageView.applyshadowWithCorner(containerView: self.shadowView, cornerRadius: 16.0, color: UIColor.red.withAlphaComponent(0.1), offset: CGSize(width: 0.0, height: -10.0), shadowRadius: 30.0)
        } else {
            self.imageView.layer.cornerRadius = 0.0
        }
    }
}
