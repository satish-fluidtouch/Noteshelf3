//
//  FTNotebookToolsHeaderView.swift
//  Noteshelf3
//
//  Created by Sameer Hussain on 03/08/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import FTCommon

enum FTNotebookTool: Int {
    case share
    case present
    case gotoPage
    case zoomBox
    
    func trackEvent() {
        let eventName : String
        switch self {
        case .share:
            eventName = FTNotebookEventTracker.nbk_more_share_tap
        case .present:
            eventName = FTNotebookEventTracker.nbk_more_present_tap
        case .gotoPage:
            eventName = FTNotebookEventTracker.nbk_more_gotopage_tap
        case .zoomBox:
            eventName = FTNotebookEventTracker.nbk_more_zoombox_tap
        }
        FTNotebookEventTracker.trackNotebookEvent(with: eventName)
    }
}
protocol FTNotebookToolDelegate: AnyObject {
    func didTapTool(type: FTNotebookTool)
}

class FTNotebookToolsHeaderView: UIView {
    @IBOutlet var numberOfPagesLabel: FTCustomLabel?
    weak var del: FTNotebookToolDelegate?
    @IBOutlet var topStackview: UIStackView?
    @IBOutlet var bottomStackview: UIStackView?
    @IBOutlet weak var macNumberOfPagesLabel: FTCustomLabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if !FTFeatureConfigHelper.shared.isFeatureEnabled(.Share) {
            topStackview?.isHidden = true
        }
        topStackview?.subviews.forEach({ eachView in
            setUp(for: eachView)
        })
        bottomStackview?.subviews.forEach({ eachView in
            setUp(for: eachView)
        })
    }
    
    func confiure(with page: FTPageProtocol) {
        let pageNumberString = String(format: NSLocalizedString("NofNAlt", comment: "%d of %d"), page.pageIndex() + 1, page.parentDocument?.pages().count ?? 0)
        numberOfPagesLabel?.text = pageNumberString
        macNumberOfPagesLabel?.text = pageNumberString
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        if let button = sender as? UIButton, let type = FTNotebookTool(rawValue: button.tag) {
            self.del?.didTapTool(type: type)
        }
    }
    
    func setUp(for view: UIView) {
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.appColor(.accentBorder).cgColor
    }
}
