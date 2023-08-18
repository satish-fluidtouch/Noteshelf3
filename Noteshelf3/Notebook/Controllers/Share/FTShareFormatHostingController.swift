//
//  FTShareFormatHostingController.swift
//  Noteshelf3
//
//  Created by Narayana on 02/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

enum FTShareType {
    case savetoCameraRoll
    case share
}
protocol FTShareFormatDelegate: AnyObject {
    func didTapOnCancel()
    func didInitiateShare(type:FTShareType)
}

class FTShareFormatHostingController: UIHostingController<FTShareContentView> {
    private let selectedOption: FTShareOption
    private let coordinator: FTShareCoordinator
    fileprivate weak var presentingVc: UIViewController?

    init(with viewModel: FTShareFormatViewModel, coordinator: FTShareCoordinator) {
        self.selectedOption = viewModel.option
        self.coordinator = coordinator
        let shareView = FTShareContentView(viewModel: viewModel)
        super.init(rootView: shareView)
        viewModel.updateDelegate(self)
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension FTShareFormatHostingController {
    class func presentAsFormsheet(over controller: UIViewController, using coordinator: FTShareCoordinator, option: FTShareOption, shelfItems: [FTShelfItemProtocol]) {
        let viewModel = FTShareFormatViewModel(option: option, shelfItems: shelfItems)
        self.shareFormsheet(over: controller, using: coordinator, viewModel: viewModel)
    }
    class func presentAsFormsheet(over controller: UIViewController, using coordinator: FTShareCoordinator, option: FTShareOption, pages: [FTPageProtocol], bookHasStandardCover: Bool = false) {
        let viewModel = FTShareFormatViewModel(option: option, pages: pages,bookHasStandardCover: bookHasStandardCover)
        self.shareFormsheet(over: controller, using: coordinator, viewModel: viewModel)
    }
    private class func shareFormsheet(over controller: UIViewController, using coordinator: FTShareCoordinator,viewModel:FTShareFormatViewModel) {
        let hostingVc = FTShareFormatHostingController(with: viewModel, coordinator: coordinator)
        hostingVc.presentingVc = controller
        let navController = UINavigationController(rootViewController: hostingVc)
        navController.navigationBar.backgroundColor = UIColor.appColor(.panelBgColor)
        controller.ftPresentFormsheet(vcToPresent: navController, hideNavBar: false)
    }
}

extension FTShareFormatHostingController: FTShareFormatDelegate {
    func didTapOnCancel() {
        self.dismiss(animated: true)
    }

    func didInitiateShare(type:FTShareType) {
#if targetEnvironment(macCatalyst)
        let properties = FTExportProperties.getSavedProperties()
        self.coordinator.presentingVc = self;
        self.coordinator.beginShare(properties, option: self.selectedOption,type: type)
#else
        self.dismiss(animated: true) {
            let properties = FTExportProperties.getSavedProperties()
            self.coordinator.beginShare(properties, option: self.selectedOption,type: type)
        }
#endif
    }
}
