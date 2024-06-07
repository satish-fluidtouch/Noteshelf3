//
//  FTPresenterShortcutHostingController.swift
//  Noteshelf3
//
//  Created by Narayana on 02/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

protocol FTPresenterShortcutDelegate: AnyObject {
    func didTapPresentationOption(_ option: FTPresenterModeOption)
    func didChangeCurrentPresenterSet(_ presenterSet: FTPresenterSetProtocol)
}

class FTPresenterShortcutHostingController: UIHostingController<FTPresenterShortcutView> {
    override init(rootView: FTPresenterShortcutView) {
        super.init(rootView: rootView)
        self.disableSafeArea()
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}

class FTPresenterSliderShortcutHostingController: FTSliderHostingController<FTPresenterSliderShortcutView> {
    override init(rootView: FTPresenterSliderShortcutView) {
        super.init(rootView: rootView)
        self.disableSafeArea()
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}
