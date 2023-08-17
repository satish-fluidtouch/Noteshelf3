//
//  FTNoteBookSegmentCell.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 10/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

class FTNoteBookSegmentCell: UITableViewCell {
    @IBOutlet weak var segmentControl: UISegmentedControl!
    override  func awakeFromNib() {
        super.awakeFromNib()
        segmentControl.setTitle(FTPageLayout.vertical.localizedTitle, forSegmentAt: FTPageLayout.vertical.rawValue)
        segmentControl.setTitle(FTPageLayout.horizontal.localizedTitle, forSegmentAt: FTPageLayout.horizontal.rawValue)
        segmentControl.selectedSegmentIndex = UserDefaults.standard.pageLayoutType.rawValue
    }
    
    @IBAction func didTapOnSegment(_ segment: UISegmentedControl) {
        if let direction = FTPageLayout(rawValue: segment.selectedSegmentIndex) {
            UserDefaults.standard.pageLayoutType = direction
        }
    }
}
