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
    }
    
    func hideDivider(_ value: Bool) {
        dividerView.isHidden = value
    }
    
    @IBAction func didTapOnSegment(_ sender: Any) {
        if let segmentControl = sender as? FTFinderSegmentControl {
            self.del?.didTapOnSegmentControl(_segmentControl: segmentControl)
        }
    }
    
    func configureHeader(count: Int, mode: FTFinderScreenMode, tab: FTFinderSelectedTab) {
        titleLabel.isHidden = (tab == .thumnails)
        descriptionLabel.isHidden = (tab == .thumnails)
        segmentControl.isHidden = (tab == .search)
        titleLeadingConstraint.constant = (mode == .fullScreen) ? 44 : 16
        descriptionTrailingConstraint.constant = (mode == .fullScreen) ? 44 : 16
        dividerView.isHidden = true
        self.selectedTab = tab
        self.titleLabel.text = "Pages".localized
        var text = "NothingFound".localized
        if count > 0 {
            let noofpages = "\(count)"
            text =  String(format: NSLocalizedString("insidenotebook.share.pagescount", comment: "%@ pages "), noofpages)
        }
        self.descriptionLabel.text = text
    }
}
