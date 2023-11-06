//
//  FTFavoriteColorEditController.swift
//  Noteshelf3
//
//  Created by Narayana on 06/11/23.
//  Copyright © 2023 Fluid Touch Pte Ltd. All rights reserved.
//

import SwiftUI
import Combine

protocol FTFavoriteColorUpdateDelegate: NSObjectProtocol {
    func didChangeColor(_ color: String)
}

class FTFavoriteColorEditController: UIHostingController<AnyView> {
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: FTFavoriteColorUpdateDelegate?

    init(penType: FTPenType, activity: NSUserActivity?) {
        let viewmodel = FTPenShortcutViewModel(rackData: FTRackData(type: penType.rackType, userActivity: activity))
        let hostView = FTPresetColorsView(selectedPage: 0)
        super.init(rootView: AnyView(hostView.environmentObject(viewmodel)))
        viewmodel.$currentSelectedColor.sink { newValue in
            self.delegate?.didChangeColor(viewmodel.currentSelectedColor)
        }
        .store(in: &self.cancellables)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
}
