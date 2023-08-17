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
}
protocol FTNotebookToolDelegate: AnyObject {
    func didTapTool(type: FTNotebookTool)
}

class FTNotebookToolsHeaderView: UIView {
    @IBOutlet var shareLabel: FTCustomLabel?
    @IBOutlet var presentLabel: FTCustomLabel?
    @IBOutlet var gotoPageLabel: FTCustomLabel?
    @IBOutlet var numberOfPagesLabel: FTCustomLabel?
    @IBOutlet var zoomLabel: FTCustomLabel?
    weak var del: FTNotebookToolDelegate?
    @IBOutlet var topStackview: UIStackView?
    @IBOutlet var bottomStackview: UIStackView?

    override func awakeFromNib() {
        super.awakeFromNib()
        topStackview?.subviews.forEach({ eachView in
            setUp(for: eachView)
        })
        bottomStackview?.subviews.forEach({ eachView in
            setUp(for: eachView)
        })
    }
    
    func confiure(with page: FTPageProtocol) {
        shareLabel?.text = "Share".localized
        presentLabel?.text = "customizeToolbar.present".localized
        gotoPageLabel?.text = "GoToPage".localized
        let pageNumberString = String(format: NSLocalizedString("NofNAlt", comment: "%d of %d"), page.pageIndex() + 1, page.parentDocument?.pages().count ?? 0)
        numberOfPagesLabel?.text = pageNumberString
        zoomLabel?.text = "ZoomBox".localized
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
