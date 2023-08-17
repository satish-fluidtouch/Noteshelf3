//
//  FTGetstartedHostingViewcontroller.swift
//  Noteshelf3
//
//  Created by Rakesh on 21/06/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

enum FTSourceScreen {
    case regular
    case settings
}

protocol FTGetstartedNavDelegate: AnyObject {
    func dismiss()
}

private var onDismissBlock  : (() -> Void)?;
private weak var welcomeScreenViewController : UIViewController?;

class FTGetstartedHostingViewcontroller: UIHostingController<FTWelcomeView> {
    var source = FTSourceScreen.regular

    private var getStartedViewmodel: FTGetStartedItemViewModel

    init(getStartedvm: FTGetStartedItemViewModel) {
        self.getStartedViewmodel = getStartedvm
        let view = FTWelcomeView(viewModel: getStartedViewmodel,source: source)
        super.init(rootView: view)
        rootView.delegate = self
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
    }
}

extension FTGetstartedHostingViewcontroller: FTGetstartedNavDelegate {
    func dismiss() {
            UserDefaults.standard.set(true, forKey: WelcomeScreenViewed)
            UserDefaults.standard.synchronize();
        self.dismiss(animated: true) {
            onDismissBlock?();
            onDismissBlock = nil;
        }
    }
}
extension FTGetstartedHostingViewcontroller{
    class func showWelcome(presenterController: UIViewController, source: FTSourceScreen = .regular, onDismiss : (() -> Void)?) {
        let welcomeController = FTGetstartedHostingViewcontroller(getStartedvm: FTGetStartedItemViewModel())
        welcomeController.source = source;
        onDismissBlock = onDismiss;
        welcomeController.modalPresentationStyle = .overFullScreen;
        welcomeController.modalTransitionStyle = .crossDissolve;
        presenterController.present(welcomeController, animated: true, completion: nil)
        if(source == .regular) {
            welcomeScreenViewController = welcomeController
        }
    }
}
