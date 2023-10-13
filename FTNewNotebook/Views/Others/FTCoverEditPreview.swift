//
//  FTCoverEditPreview.swift
//  Noteshelf3
//
//  Created by Sameer on 17/01/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import FTCommon
import SDWebImage

class FTCoverEditPreview: UIView {
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private(set) weak var selectedImageView: UIImageView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView?
    @IBOutlet weak var spineImgView: UIImageView?
    var scaledRect: CGRect = .zero
    var rawImage: UIImage?
    private var isDownloading: Bool = false {
        didSet {
            if isDownloading {
                self.selectedImageView.alpha = 0.3
                self.loadingIndicator?.isHidden = false
                self.loadingIndicator?.startAnimating()
            } else {
                self.selectedImageView.alpha = 1.0
                self.loadingIndicator?.stopAnimating()
                self.loadingIndicator?.isHidden = true
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.spineImgView?.image = nil
        self.loadingIndicator?.isHidden = true
        self.scrollView.delegate = self
    }

    private func setUpScrollView() {
        self.scrollView.isScrollEnabled = true
        self.scrollView.setZoomScale(1.0, animated: false)
        self.scrollView.setContentOffset(.zero, animated: false)
        self.scrollView.contentSize = self.selectedImageView.image!.size
        self.scrollView.decelerationRate = .fast
        self.selectedImageView.transform = .identity
        self.selectedImageView.frame = .zero
        self.selectedImageView.frame.size = CGSize(width: self.selectedImageView.image!.size.width, height: self.selectedImageView.image!.size.height)
        self.scrollView.minimumZoomScale = max(self.scrollView.frame.size.width / selectedImageView.image!.size.width, self.scrollView.frame.size.height / selectedImageView.image!.size.height)
        self.scrollView.maximumZoomScale = max(self.scrollView.minimumZoomScale, 1.0);
        self.scrollView.zoom(to: selectedImageView.frame, animated: false)
    }

    func updatePreviewIfNeeded(_ image: UIImage?) {
        self.rawImage = image
        self.selectedImageView.image = image
        self.setUpScrollView()
        self.updateScaledRect()
        self.spineImgView?.image = UIImage(named: "cover_spine", in: currentBundle, compatibleWith: nil)
    }

    func updateAsynchronousImage(using url: String, placeholder: UIImage?) {
        self.isDownloading = true
        if let reqUrl = URL(string: url) {
            self.selectedImageView.sd_setImage(with: reqUrl,
                                               placeholderImage: placeholder,
                                               options: [SDWebImageOptions.refreshCached],
                                               completed: { img, error, cacheType, _ in
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    return
                }
                self.isDownloading = false
                if let image = img {
                    self.updatePreviewIfNeeded(image)
                    FTCurrentCoverSelection.shared.selectedCover = nil
                }
            })
        }
    }
    
    private func updateScaledRect() {
        let scaledOrigin = scrollView.contentOffset.scaled(scale: 1 / self.scrollView.zoomScale)
        var size = scrollView.frame.size
        size.scale(scale: 1 / self.scrollView.zoomScale)
        self.scaledRect = CGRect(origin: scaledOrigin, size: size)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updateScaledRect()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.updateScaledRect()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.updateScaledRect()
    }
}

extension FTCoverEditPreview: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return selectedImageView
    }
}
