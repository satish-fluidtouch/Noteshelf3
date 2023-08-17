//
//  FTPasswordHostController.swift
//  Noteshelf3
//
//  Created by Ramakrishna on 23/02/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation
import SwiftUI
import FTNewNotebook

class FTPasswordHostController: UIHostingController<FTPasswordView> {
    private var passwordView: FTPasswordView!
    var passwordDetails: FTPasswordModel?
    init(passwordViewDelegate: FTPasswordDelegate? = nil,passwordDetails: FTPasswordModel?) {
        let viewModel = FTPasswordViewModel()
        viewModel.passwordDetails = passwordDetails
        passwordView = FTPasswordView(viewModel: viewModel)
        passwordView.passwordDelegate = passwordViewDelegate
        super.init(rootView: passwordView)
        self.rootView.viewDelegate = self
    }
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let viewHeight = FTBiometricManager.shared().isTouchIDEnabled() ? 440 : 396
        self.preferredContentSize = CGSize(width: 330, height: viewHeight)
    }
}
extension FTPasswordHostController: FTPasswordViewDelegate {
    func dismissPasswordView() {
        self.dismiss(animated: true)
    }
}
