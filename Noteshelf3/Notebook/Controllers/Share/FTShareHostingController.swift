//
//  FTShareHostingController.swift
//  Noteshelf3
//
//  Created by Narayana on 02/11/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import FTStyles
import FTCommon

var shareContentSize = CGSize(width: defaultPopoverWidth, height: 270)

protocol FTShareDelegate: AnyObject {
    func didSelectShareOption(_ option: FTShareOption)
    func didTapBackButton()
}

class FTShareHostingController: UIHostingController<FTShareView>, FTPopoverPresentable {
    var ftPresentationDelegate:FTPopoverPresentation = FTPopoverPresentation()
    weak var delegate: FTShareBeginnerDelegate?

    init(with viewModel: FTShareViewModel, showBackButton: Bool = false) {
        let shareView = FTShareView(viewModel: viewModel, showBackButton: showBackButton)
        super.init(rootView: shareView)
        viewModel.updateDelegate(self)
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.preferredContentSize = shareContentSize
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.navigationController?.preferredContentSize = shareContentSize
    }
}

extension FTShareHostingController: FTShareDelegate {
    func didSelectShareOption(_ option: FTShareOption) {
        self.dismiss(animated: true) {
            self.delegate?.didSelectShareOption(option: option)
        }
    }
    
    func didTapBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension FTShareHostingController {
    class func showAsPopover(from controller: UIViewController, source: FTCenterToolSourceItem, info: FTShareOptionsInfo) -> FTShareHostingController {
        let hostingVc = FTShareHostingController(with: FTShareViewModel(info: info))
        hostingVc.view.backgroundColor = UIColor.appColor(.popoverBgColor)
        hostingVc.ftPresentationDelegate.source = source
        controller.ftPresentPopover(vcToPresent: hostingVc, contentSize: shareContentSize, hideNavBar: true)
        return hostingVc
    }

    class func pushShareVc(from controller: UIViewController, info: FTShareOptionsInfo) -> FTShareHostingController {
        let hostingVc = FTShareHostingController(with: FTShareViewModel(info: info), showBackButton: true)
        hostingVc.view.backgroundColor = UIColor.appColor(.popoverBgColor)
        controller.navigationController?.pushViewController(hostingVc, animated: true)
        return hostingVc
    }
}

