//
//  FTFinderCollectionViewHeader.swift
//  Noteshelf3
//
//  Created by Sameer on 26/07/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
protocol FTFinderHeaderDelegate: AnyObject {
    func didTapClearButton()
    func didTapOnSegmentControl(_segmentControl: FTFinderSegmentControl)
}

class FTFinderCollectionViewHeader: UICollectionReusableView {
    @IBOutlet weak var collectionViewHeaderLeadingConstraint: NSLayoutConstraint!
//    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var descriptionTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    weak var del: FTFinderHeaderDelegate?
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    var selectedTab = FTFinderSelectedTab.thumnails
    @IBOutlet weak var segmentControl: FTFinderSegmentControl!
    @IBAction func didTapClearButton(_ sender: Any) {
        self.del?.didTapClearButton()
    }
    
    override  func awakeFromNib() {
        super.awakeFromNib()
        segmentControl.type = .text
        segmentControl.populateSegments()
        segmentControl.selectedSegmentIndex = 0
        self.activityIndicator.isHidden = true
    }
    
    func hideDivider(_ value: Bool) {
        dividerView.isHidden = value
    }
    
    @IBAction func didTapOnSegment(_ sender: Any) {
        if let segmentControl = sender as? FTFinderSegmentControl {
            self.del?.didTapOnSegmentControl(_segmentControl: segmentControl)
        }
    }
    
    func showSearchIndicator(_ value : Bool) {
        if value {
            if !self.activityIndicator.isAnimating {
                self.titleLabel.text = "Searching".localized
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            }
        } else {
            self.titleLabel.text = "Results".localized
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
        }
    }
    
    func updateCountLabel(with count: Int) {
        var text = "NothingFound".localized
        if count > 0 {
            let noofpages = "\(count)"
            text =  String(format: NSLocalizedString("insidenotebook.share.pagescount", comment: "%@ pages "), noofpages)
        }
        self.descriptionLabel.text = text
    }
    
    func configureHeader(count: Int, mode: FTFinderScreenMode, tab: FTFinderSelectedTab) {
        titleLabel.isHidden = (tab == .thumnails)
        descriptionLabel.isHidden = (tab == .thumnails)
        segmentControl.isHidden = (tab == .search)
        titleLeadingConstraint.constant = (mode == .fullScreen) ? 44 : 16
        descriptionTrailingConstraint.constant = (mode == .fullScreen) ? 44 : 16
        dividerView.isHidden = true
        self.selectedTab = tab
        self.updateCountLabel(with: count)
    }
}
