//
//  FTPenShortcutHostingController.swift
//  Noteshelf3
//
//  Created by Narayana on 02/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//
import SwiftUI

class FTPenShortcutHostingController: UIHostingController<FTPenShortcutView> {

    override init(rootView: FTPenShortcutView) {
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

class FTPenSliderShortcutHostingController: UIHostingController<FTPenSliderShortcutView> {

    override init(rootView: FTPenSliderShortcutView) {
        super.init(rootView: rootView)
        self.disableSafeArea()
    }

    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .gray
    }
}
