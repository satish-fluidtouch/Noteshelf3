//
//  FTShapeEditHostingController.swift
//  Noteshelf3
//
//  Created by Narayana on 01/09/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI

class FTShapeShortcutHostingController: UIHostingController<FTShapeShortcutView> {
    override init(rootView: FTShapeShortcutView) {
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

class FTShapeCurvedShortcutHostingController: UIHostingController<FTShapeCurvedShortcutView> {
    override init(rootView: FTShapeCurvedShortcutView) {
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
