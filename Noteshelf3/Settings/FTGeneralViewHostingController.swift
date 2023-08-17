//
//  FTGeneralViewHostingController.swift
//  Noteshelf3
//
//  Created by Rakesh on 29/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI


protocol FTGeneralViewHostingControllerNavDelegate: AnyObject {
    func dismiss()
}

class FTGeneralViewHostingController: UIHostingController<FTGeneralSettingsView> {

    init() {
        super.init(rootView: FTGeneralSettingsView())
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FTGeneralViewHostingController: FTGeneralViewHostingControllerNavDelegate {
    func dismiss() {
        self.dismiss(animated: true)
    }
}
