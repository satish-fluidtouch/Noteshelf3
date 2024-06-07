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

protocol FTSliderHostingControllerProtocol {
    func removeHost()
}

class FTSliderHostingController<Content: View>: UIHostingController<Content>, FTSliderHostingControllerProtocol {
    override init(rootView: Content) {
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func removeHost() {
        self.remove()
    }
}

class FTPenSliderShortcutHostingController: FTSliderHostingController<FTPenSliderShortcutView> {

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
        self.view.backgroundColor = .green
    }
}
