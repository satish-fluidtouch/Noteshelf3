//
//  FTStickersViewController.swift
//  Noteshelf3
//
//  Created by Narayana on 21/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import FTStyles
import SwiftUI
import FTCommon

class FTStickersViewController: UIHostingController<FTStickerCategoriesView>, FTPopoverPresentable {
    var ftPresentationDelegate = FTPopoverPresentation()

    override init(rootView: FTStickerCategoriesView) {
        super.init(rootView: rootView)
    }
    
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 320.0, height: 544.0)
        self.view.backgroundColor = UIColor.appColor(.popoverBgColor)
        let dropInteraction = UIDropInteraction(delegate: self)
        self.view.addInteraction(dropInteraction)
    }
}

extension FTStickersViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        self.dismiss(animated: true)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .move)
    }
}

extension FTStickersViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}
