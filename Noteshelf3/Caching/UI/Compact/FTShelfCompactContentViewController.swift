//
//  FTShelfCompactContentViewController.swift
//  Noteshelf3
//
//  Created by Akshay on 16/12/22.
//  Copyright © 2022 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class FTShelfCompactContentViewController: UIHostingController<FTShelfCompactContentContainerView> {
    init() {
        let view = FTShelfCompactContentContainerView()
        super.init(rootView: view)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
