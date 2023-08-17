//
//  FTGeneralViewHostingController.swift
//  Noteshelf3
//
//  Created by Rakesh on 29/05/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI


protocol FTAboutNoteShelfViewHostingControllerNavDelegate: AnyObject {
    func dismiss()
}

class FTAboutNoteShelfViewHostingController: UIHostingController<FTSettingsAboutView> {
    private var aboutsettingsVm: FTSettingsAboutViewModel

    init(aboutsettingsVm: FTSettingsAboutViewModel) {
        self.aboutsettingsVm = aboutsettingsVm
        let view = FTSettingsAboutView(viewModel: aboutsettingsVm)
        super.init(rootView: view)
        rootView.delegate = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FTAboutNoteShelfViewHostingController: FTAboutNoteShelfViewHostingControllerNavDelegate {
    func dismiss() {
        self.dismiss(animated: true)
    }
}
