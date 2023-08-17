//
//  FTAppearanceViewHostingController.swift
//  Noteshelf3
//
//  Created by Rakesh on 10/07/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI


protocol FTAppearanceViewHostingControllerNavDelegate: AnyObject {
    func dismiss()
}

class FTAppearanceViewHostingController: UIHostingController<FTAppearanceView> {

    init() {
        super.init(rootView: FTAppearanceView())
        rootView.delegate = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FTAppearanceViewHostingController: FTAppearanceViewHostingControllerNavDelegate {
    func dismiss() {
        self.dismiss(animated: true)
    }
}
